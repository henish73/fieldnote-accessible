param([string]$Base, [string]$Report)
# Fieldnote redesign test suite: functional, keyboard usability, accessibility (axe-core), UI/UX layout checks.
$ErrorActionPreference = 'Stop'
$edge = "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
$prof = Join-Path $env:TEMP ("cdp_suite_" + [guid]::NewGuid().ToString('N'))
$proc = Start-Process $edge -ArgumentList "--headless=new","--remote-debugging-port=9335","--user-data-dir=$prof","--window-size=1100,800","--hide-scrollbars","about:blank" -PassThru
Start-Sleep -Seconds 3
$ws = ((Invoke-RestMethod "http://127.0.0.1:9335/json") | Where-Object { $_.type -eq 'page' } | Select-Object -First 1).webSocketDebuggerUrl
$sock = New-Object System.Net.WebSockets.ClientWebSocket; $ct = [Threading.CancellationToken]::None
$sock.ConnectAsync([Uri]$ws, $ct).Wait()
$script:id = 0
function Cdp($method, $params) {
  $script:id++
  $bytes = [Text.Encoding]::UTF8.GetBytes((@{ id = $script:id; method = $method; params = $params } | ConvertTo-Json -Depth 10 -Compress))
  $sock.SendAsync([ArraySegment[byte]]::new($bytes), 'Text', $true, $ct).Wait()
  while ($true) {
    $ms = New-Object IO.MemoryStream
    do { $buf = New-Object byte[] 1048576; $r = $sock.ReceiveAsync([ArraySegment[byte]]::new($buf), $ct).Result; $ms.Write($buf, 0, $r.Count) } while (-not $r.EndOfMessage)
    $o = [Text.Encoding]::UTF8.GetString($ms.ToArray()) | ConvertFrom-Json
    if ($o.id -eq $script:id) { return $o }
  }
}
$codes = @{ Tab = 9; Enter = 13; ArrowDown = 40; ArrowUp = 38; Escape = 27; ' ' = 32 }
$script:keys = 0
function Key($k, [int]$mod = 0) {
  $script:keys++
  $p = @{ key = $k; code = $k; windowsVirtualKeyCode = $codes[$k]; modifiers = $mod }
  if ($k -eq 'Enter') { $p.text = "`r" }
  Cdp 'Input.dispatchKeyEvent' ($p + @{ type = 'keyDown' }) | Out-Null
  Cdp 'Input.dispatchKeyEvent' ($p + @{ type = 'keyUp' }) | Out-Null
  Start-Sleep -Milliseconds 60
}
function Char($c) { $script:keys++; Cdp 'Input.dispatchKeyEvent' @{ type = 'keyDown'; key = $c; text = $c } | Out-Null; Cdp 'Input.dispatchKeyEvent' @{ type = 'keyUp'; key = $c } | Out-Null; Start-Sleep -Milliseconds 60 }
function Typ($t) { $script:keys++; Cdp 'Input.insertText' @{ text = $t } | Out-Null; Start-Sleep -Milliseconds 40 }   # typing a phrase counts as one step
function Js($e) { $r = Cdp 'Runtime.evaluate' @{ expression = $e; awaitPromise = $true; returnByValue = $true }; if ($r.result.exceptionDetails) { return "JSERR: " + $r.result.exceptionDetails.exception.description } ; $r.result.result.value }
function Nav($u) { Cdp 'Page.navigate' @{ url = 'about:blank' } | Out-Null; Cdp 'Page.navigate' @{ url = $u } | Out-Null; for ($w = 0; $w -lt 60; $w++) { if ((Cdp 'Runtime.evaluate' @{ expression = "document.readyState==='complete'&&!!document.getElementById('view-title')"; returnByValue = $true }).result.result.value -eq $true) { break }; Start-Sleep -Milliseconds 25 } }
function Act() { Js "(()=>{const a=document.activeElement;return a.id||a.tagName})()" }
function Hash() { Js "location.hash" }
function Size($w, $h) { Cdp 'Emulation.setDeviceMetricsOverride' @{ width = $w; height = $h; deviceScaleFactor = 1; mobile = ($w -lt 600) } | Out-Null; Start-Sleep -Milliseconds 120 }

$results = New-Object System.Collections.Generic.List[object]
function T($group, $name, [bool]$ok, $detail = '') { $results.Add([pscustomobject]@{ Group = $group; Test = $name; Result = $(if ($ok) { 'PASS' } else { 'FAIL' }); Detail = $detail }) }

Size 1100 800
Nav "$Base#home"; Js "localStorage.clear();1" | Out-Null; Nav "$Base#home"

# ---------------- functional ----------------
$g = 'Functional'
Char '/'; T $g "'/' moves focus to the search box" ((Act) -eq 'query')
Key 'Enter'; T $g 'Empty search shows an error instead of doing nothing' ((Js "!document.getElementById('query-error').hidden && document.getElementById('query').getAttribute('aria-invalid')==='true'") -eq $true)
Typ 'bike'; Key 'ArrowDown'
T $g 'Down arrow opens suggestions and highlights the first one' ((Js "document.getElementById('query').getAttribute('aria-expanded')==='true' && document.getElementById('query').getAttribute('aria-activedescendant')==='opt-0'") -eq $true)
Key 'Escape'; T $g 'Escape closes suggestions' ((Js "document.getElementById('suggest').hidden") -eq $true)
Js "document.getElementById('query').select();1" | Out-Null
Typ 'campus bike repair'; Key 'Enter'
T $g 'Enter submits the search and focus moves to the results heading' ((Act) -eq 'view-title' -and (Hash) -eq '#q=campus+bike+repair') (Js "document.getElementById('view-title').textContent")
T $g 'Error clears after a valid search' ((Js "document.getElementById('query-error').hidden") -eq $true)
T $g 'Page title names the view' ((Js "document.title") -like '10 results*')
Js "document.getElementById('page-2').click();1" | Out-Null
T $g 'Paging: page 2 opens and is marked current' ((Hash) -like '*page=2*' -and (Js "document.getElementById('page-2').getAttribute('aria-current')") -eq 'page')
Nav "$Base#q=campus+bike+repair"
Js "document.getElementById('cat-Events').focus();1" | Out-Null; Key 'Enter'
T $g 'Enter on a type button applies it' ((Hash) -eq '#q=campus+bike+repair&type=Events')
Start-Sleep -Milliseconds 200
T $g 'Type change is announced in words' ((Js "document.getElementById('status').textContent") -like 'type Events. 4 results*')
Js "document.getElementById('f-all').focus();1" | Out-Null; Key 'ArrowDown'
T $g 'Arrow key picks Free only' ((Hash) -eq '#q=campus+bike+repair&type=Events&filter=free')
T $g 'Filtered list shows Free/Paid in words, past event grouped' ((Js "document.querySelectorAll('ol.results .badge.free').length===3 && !!document.getElementById('past-h')") -eq $true)
Char 'u'; T $g "'u' undoes the last change" ((Hash) -eq '#q=campus+bike+repair&type=Events')
Js "document.getElementById('f-free').focus();1" | Out-Null; Key 'Enter'
T $g 'Enter on a radio choice selects it' ((Hash) -like '*filter=free*')
Js "document.getElementById('reset-btn').click();1" | Out-Null
T $g "'Show all results again' clears type and filter" ((Hash) -eq '#q=campus+bike+repair')
Nav "$Base#q=campus+bike+repair&type=Events&filter=free"
Js "document.getElementById('open-flat-tire').focus();1" | Out-Null; Key 'Enter'
T $g 'Opening a result moves focus to its heading' ((Act) -eq 'view-title' -and (Hash) -like '*item=flat-tire')
T $g 'Event page shows when, cost and a copy button' ((Js "(()=>{const t=document.querySelector('.facts').innerText;return t.includes('Nov 28')&&t.includes('Free')&&!!document.getElementById('copy-btn')})()") -eq $true)
Key 'Tab' 8; Key 'Enter'
T $g 'Back returns focus to the same result' ((Act) -eq 'open-flat-tire')
Js "document.getElementById('open-flat-tire').click();1" | Out-Null; Js "history.back();1" | Out-Null; Start-Sleep -Milliseconds 600
T $g 'Browser Back button returns to the results' ((Hash) -eq '#q=campus+bike+repair&type=Events&filter=free') (Hash)
Nav "$Base#q=campus+bike+repair&item=north-quad"
T $g 'Task 3: map has a text purpose naming the repair stand marker' ((Js "document.getElementById('map-purpose').textContent.includes('Repair stand is marker 1 (circle')") -eq $true)
T $g 'Task 3: places listed in text with shape and position' ((Js "document.querySelectorAll('ol.places li').length") -eq 2)
Nav "$Base#q=purple+toaster+orchestra"
Js "document.getElementById('edit-search').click();1" | Out-Null
T $g "Task 4: 'Edit your search' selects the old words" ((Js "(()=>{const q=document.getElementById('query');return document.activeElement===q&&q.selectionStart===0&&q.selectionEnd===q.value.length})()") -eq $true)
Js "document.querySelector('#empty .chips button').click();1" | Out-Null
T $g 'Task 4: a suggested search gives results' ((Js "document.getElementById('view-title').textContent") -like '10 results*')
Nav "$Base#q=dancing+umbrella+parade&type=Events&filter=free"
T $g 'No results with filters offers to search without them' ((Js "!!document.getElementById('empty-reset')") -eq $true)
Nav "$Base#q=library+workshop&type=Events&filter=free"
T $g 'Set B: library workshop filter finds the citation workshop' ((Js "document.querySelector('ol.results .title').textContent") -eq 'Citation and reference manager workshop')
Nav "$Base#q=library+study+rooms&item=quiet-study"
T $g 'Set B: quiet study map names its marker' ((Js "document.getElementById('map-purpose').textContent.includes('Quiet study is marker 1')") -eq $true)
Nav "$Base#q=campus+bike+repair"
Js "document.getElementById('view-title').focus();1" | Out-Null
Char '?'; T $g "'?' opens the shortcuts dialog with focus inside" ((Js "document.getElementById('keys').open && document.getElementById('keys').contains(document.activeElement)") -eq $true)
Js "document.getElementById('keys-on').click(); document.getElementById('keys-close').click();1" | Out-Null
Js "document.getElementById('view-title').focus();1" | Out-Null
Char 'r'; T $g 'Shortcuts can be turned off (WCAG 2.1.4)' ((Act) -eq 'view-title')
Js "localStorage.setItem('fieldnote:shortcuts','true');1" | Out-Null
Nav "$Base#q=campus+bike+repair&type=Maps"
T $g 'Refreshing a link restores the same view' ((Js "document.getElementById('cat-Maps').getAttribute('aria-pressed')") -eq 'true')
Js "document.getElementById('query').value='abc';document.getElementById('query').dispatchEvent(new Event('input'));document.getElementById('clear').click();1" | Out-Null
T $g 'Clear empties the box and keeps focus there' ((Js "document.getElementById('query').value===''&&document.activeElement.id==='query'") -eq $true)

# ---------------- keyboard usability: key presses per task ----------------
$g = 'Usability (keystrokes)'
function Task($name, [scriptblock]$steps, $check, $max) {
  Nav "$Base#home"; Js "localStorage.clear();1" | Out-Null; Nav "$Base#home"; $script:keys = 0
  & $steps
  $ok = (Js $check) -eq $true
  T $g "$name in $($script:keys) steps (target <= $max)" ($ok -and $script:keys -le $max) $(if (-not $ok) { 'end state wrong' } else { '' })
}
Task 'Task 1: search, open a result, go back' { Char '/'; Typ 'campus bike repair'; Key 'Enter'; Char 'r'; Key 'Enter'; Key 'Tab' 8; Key 'Enter' } "document.activeElement.id==='open-bike-hub'" 8
Task 'Task 2: record a free workshop' { Char '/'; Typ 'campus bike repair'; Key 'Enter'; Key 'Tab'; Key 'Tab'; Key 'Tab'; Key 'Enter'; Key 'Tab'; Key 'Tab'; Key 'ArrowDown'; Char 'r'; Key 'Tab' } "document.activeElement.id==='open-flat-tire'&&location.hash.includes('filter=free')" 13
Task 'Task 3: open the North Quad map' { Char '/'; Typ 'campus bike repair'; Key 'Enter'; Char 'r'; Key 'Tab'; Key 'Tab'; Key 'Tab'; Key 'Enter' } "!!document.getElementById('map-purpose')" 9
Task 'Task 4: recover from no results' { Char '/'; Typ 'purple toaster orchestra'; Key 'Enter'; Key 'Tab'; Key 'Tab'; Key 'Enter' } "document.getElementById('view-title').textContent.startsWith('10 results')" 7

# ---------------- accessibility (axe-core WCAG 2.2 AA) ----------------
$g = 'Accessibility'
$axe = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'axe.min.js'))
$views = [ordered]@{ 'Home' = '#home'; 'Results' = '#q=campus+bike+repair'; 'Filtered' = '#q=campus+bike+repair&type=Events&filter=free'; 'No results' = '#q=purple+toaster+orchestra'; 'No results + filters' = '#q=dancing+umbrella+parade&type=Events&filter=free'; 'Event page' = '#q=campus+bike+repair&item=flat-tire'; 'Map page' = '#q=campus+bike+repair&item=north-quad' }
foreach ($v in $views.Keys) {
  Nav "$Base$($views[$v])"
  Cdp 'Runtime.evaluate' @{ expression = $axe } | Out-Null
  $r = Js "axe.run(document,{runOnly:{type:'tag',values:['wcag2a','wcag2aa','wcag21a','wcag21aa','wcag22aa','best-practice']}}).then(r=>JSON.stringify(r.violations.map(v=>v.id+'('+v.nodes.length+')')))"
  T $g "axe-core: no violations on $v" ($r -eq '[]') $r
}
Cdp 'Runtime.evaluate' @{ expression = 'document.getElementById("keys").showModal()' } | Out-Null
$r = Js "axe.run(document.getElementById('keys'),{runOnly:{type:'tag',values:['wcag2a','wcag2aa','wcag22aa']}}).then(r=>JSON.stringify(r.violations.map(v=>v.id)))"
T $g 'axe-core: no violations in the shortcuts dialog' ($r -eq '[]') $r

# ---------------- structure ("indexing") ----------------
$g = 'Structure and order'
foreach ($v in $views.Keys) {
  Nav "$Base$($views[$v])"
  $h = Js "(()=>{const hs=[...document.querySelectorAll('h1,h2,h3,h4')].filter(h=>h.offsetParent);const lv=hs.map(h=>+h.tagName[1]);let bad=lv[0]!==1||lv.filter(x=>x===1).length!==1;for(let i=1;i<lv.length;i++)if(lv[i]-lv[i-1]>1)bad=true;return (bad?'BAD ':'OK ')+lv.join('')})()"
  T $g "$($v): one h1, no skipped heading levels" ($h -like 'OK*') $h
}
Nav "$Base#q=campus+bike+repair"
T $g 'Landmarks: banner, search, main, contentinfo present' ((Js "!!document.querySelector('header')&&!!document.querySelector('[role=search]')&&!!document.querySelector('main')&&!!document.querySelector('footer')") -eq $true)
T $g 'Page language set' ((Js "document.documentElement.lang") -eq 'en')
T $g 'No positive tabindex anywhere' ((Js "document.querySelectorAll('[tabindex]:not([tabindex=\""-1\""]):not([tabindex=\""0\""])').length") -eq 0)
foreach ($v in @('Results','Filtered','Event page')) {
  Nav "$Base$($views[$v])"
  $o = Js "(async()=>{const seq=[];document.activeElement.blur();document.body.focus();return 1})()"
  $seq = @()
  for ($i = 0; $i -lt 40; $i++) { Key 'Tab'; $p = Js "(()=>{const a=document.activeElement;if(!a||a===document.body)return null;const r=a.getBoundingClientRect();return JSON.stringify({id:a.id||a.textContent.trim().slice(0,20),y:Math.round(r.top+scrollY),x:Math.round(r.left),vis:r.width>0&&r.height>0})})()"; if (-not $p) { break }; $o2 = $p | ConvertFrom-Json; if ($seq.Count -gt 0 -and $o2.id -eq $seq[0].id) { break }; $seq += $o2 }
  $main = $seq | Where-Object { $_.y -gt 0 }
  $back = 0; for ($i = 1; $i -lt $main.Count; $i++) { if ($main[$i].y -lt $main[$i-1].y - 30 -and $main[$i].x -le $main[$i-1].x + 150) { $back++ } }   # moving up into the next column to the right is normal column reading order
  T $g "$($v): Tab order follows reading order (top to bottom)" ($back -eq 0) "$($seq.Count) stops, $back backward jumps"
  T $g "$($v): every Tab stop is visible on screen" (($seq | Where-Object { -not $_.vis }).Count -eq 0)
}
$script:keys = 0

# ---------------- UI/UX layout ----------------
$g = 'UI/UX layout'
Size 1100 800
foreach ($v in $views.Keys) {
  Nav "$Base$($views[$v])"
  $small = Js "JSON.stringify([...document.querySelectorAll('button,a[href],input,[tabindex=\""0\""]')].filter(e=>e.offsetParent&&!e.closest('#skips')).map(e=>{const t=(e.type==='radio'||e.type==='checkbox')?e.closest('label'):e;const r=t.getBoundingClientRect();return {n:(e.id||e.textContent.trim()).slice(0,24),w:Math.round(r.width),h:Math.round(r.height)}}).filter(o=>o.w<44||o.h<44))"
  T $g "$($v): every control is at least 44x44 px" ($small -eq '[]') $small
  $nofocus = Js "JSON.stringify([...document.querySelectorAll('button,a[href],input')].filter(e=>e.offsetParent).filter(e=>{e.focus({focusVisible:true});const t=e.matches('#query')?e.closest('.box'):e.type==='radio'?e.closest('label'):e;const s=getComputedStyle(t);return s.outlineStyle==='none'&&s.boxShadow==='none'}).map(e=>e.id||e.textContent.trim().slice(0,20)))"
  T $g "$($v): every control shows a focus indicator" ($nofocus -eq '[]') $nofocus
}
# spacing rhythm: vertical gaps between sibling blocks in main use a small set of values
Nav "$Base#q=campus+bike+repair&type=Events&filter=free"
$gaps = Js "(()=>{const els=[...document.querySelectorAll('main > *')].filter(e=>e.offsetParent&&!e.classList.contains('sr-only'));const g=[];for(let i=1;i<els.length;i++){g.push(Math.round(els[i].getBoundingClientRect().top-els[i-1].getBoundingClientRect().bottom))}return JSON.stringify(g)})()"
T $g 'Spacing: no overlapping blocks in the results page' ((($gaps | ConvertFrom-Json) | Where-Object { $_ -lt 0 }).Count -eq 0) "gaps px: $gaps"
$left = Js "(()=>{const xs=[document.querySelector('form.search label'),document.getElementById('view-title'),document.querySelector('.controls')].map(e=>Math.round(e.getBoundingClientRect().left));return JSON.stringify(xs)})()"
T $g 'Alignment: search, heading and filters share one left edge' (((($left | ConvertFrom-Json) | Sort-Object -Unique).Count) -eq 1) "left x: $left"
$lh = Js "(()=>{const p=document.querySelector('.desc');const s=getComputedStyle(p);return (parseFloat(s.lineHeight)/parseFloat(s.fontSize)).toFixed(2)+' / '+s.fontSize})()"
T $g 'Readable body text: line height at least 1.5, size at least 16 px' ([double]($lh.Split(' ')[0]) -ge 1.5 -and [double]($lh -replace '.*/ ','' -replace 'px','') -ge 16) $lh
$ml = Js "Math.round(document.querySelector('.desc').getBoundingClientRect().width / parseFloat(getComputedStyle(document.querySelector('.desc')).fontSize))"
T $g 'Line length stays readable (under ~90 characters)' ([int]$ml -le 45) "about $([int]$ml * 2) characters per line"
foreach ($w in 320, 640) {
  Size $w 800
  foreach ($v in $views.Keys) {
    Nav "$Base$($views[$v])"
    $ov = Js "document.documentElement.scrollWidth - innerWidth"
    T $g "Reflow at $w px (= 400%/200% zoom): no sideways scroll on $v" ([int]$ov -le 0) "overflow $ov px"
  }
}
Size 1100 800
Nav "$Base#q=campus+bike+repair&type=Events&filter=free"
Js "(()=>{const s=document.createElement('style');s.textContent='*{line-height:1.5!important;letter-spacing:.12em!important;word-spacing:.16em!important}p{margin-bottom:2em!important}';document.head.appendChild(s);return 1})()" | Out-Null
$clip = Js "JSON.stringify([...document.querySelectorAll('main *')].filter(e=>e.offsetParent&&!e.closest('.sr-only')&&(e.scrollWidth>e.clientWidth+1)&&getComputedStyle(e).overflow!=='visible').map(e=>e.className||e.tagName).slice(0,5))"
T $g 'Text spacing override (WCAG 1.4.12): nothing is clipped' ($clip -eq '[]') $clip
Cdp 'Emulation.setEmulatedMedia' @{ features = @(@{ name = 'prefers-reduced-motion'; value = 'reduce' }) } | Out-Null
Nav "$Base#q=campus+bike+repair"
Js "document.getElementById('cat-Maps').click();1" | Out-Null
T $g 'Reduced motion: change highlight does not animate' ((Js "getComputedStyle(document.getElementById('summary')).animationName") -eq 'none')

$sock.Dispose()
& taskkill.exe /PID $proc.Id /T /F | Out-Null

$pass = ($results | Where-Object Result -eq 'PASS').Count; $fail = ($results | Where-Object Result -eq 'FAIL').Count
$md = @("# Fieldnote redesign test report", "", "Run: $(Get-Date -Format 'yyyy-MM-dd HH:mm') - headless Microsoft Edge - $Base", "", "**$pass passed, $fail failed** ($($results.Count) tests)", "")
foreach ($grp in ($results | Select-Object -ExpandProperty Group -Unique)) {
  $md += "## $grp", "", "| Result | Test | Detail |", "| --- | --- | --- |"
  foreach ($r in ($results | Where-Object Group -eq $grp)) { $md += "| $($r.Result) | $($r.Test) | $(($r.Detail -replace '\|','/'))|" }
  $md += ""
}
[IO.File]::WriteAllLines($Report, $md)
"$pass passed, $fail failed"
$results | Where-Object Result -eq 'FAIL' | Format-Table -AutoSize -Wrap | Out-String -Width 220

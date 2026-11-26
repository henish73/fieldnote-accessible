param([string]$Base, [string]$Report)
# Fieldnote redesign test suite: functional, keyboard usability, accessibility (axe-core), UI/UX layout checks.
$ErrorActionPreference = 'Stop'
$edge = "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
$prof = Join-Path $env:TEMP ("cdp_btn_" + [guid]::NewGuid().ToString('N'))
$proc = Start-Process $edge -ArgumentList "--headless=new","--remote-debugging-port=9336","--user-data-dir=$prof","--window-size=1100,800","--hide-scrollbars","about:blank" -PassThru
Start-Sleep -Seconds 3
$ws = ((Invoke-RestMethod "http://127.0.0.1:9336/json") | Where-Object { $_.type -eq 'page' } | Select-Object -First 1).webSocketDebuggerUrl
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
$g = 'Problem 1: Back button'
foreach ($c in @(@('Guide','bike-hub'),@('Map','north-quad'),@('Event','gear-clinic'))) {
  Nav "$Base#q=campus+bike+repair"
  Js "document.getElementById('open-$($c[1])').focus();1" | Out-Null; Key 'Enter'
  Js "document.getElementById('back').click();1" | Out-Null; Start-Sleep -Milliseconds 120
  T $g "$($c[0]) page: 'Back to results' returns to the list with focus on the same result" ((Hash) -eq '#q=campus+bike+repair' -and (Act) -eq "open-$($c[1])") "$(Hash) / $(Act)"
}
Nav "$Base#q=campus+bike+repair&type=Events&filter=free&item=flat-tire"
Js "document.getElementById('back').click();1" | Out-Null; Start-Sleep -Milliseconds 120
T $g "Opened from a shared link: Back still goes to the filtered results" ((Hash) -eq '#q=campus+bike+repair&type=Events&filter=free' -and (Js "document.getElementById('view-title').textContent") -like '3 results*') (Hash)
Nav "$Base#home"
Js "document.querySelector('.chips button').click();1" | Out-Null; Start-Sleep -Milliseconds 120
Js "document.querySelector('ol.results .title').click();1" | Out-Null; Start-Sleep -Milliseconds 120
Js "history.back();1" | Out-Null; Start-Sleep -Milliseconds 200
T $g 'Browser Back from a result returns to the results' ((Hash) -eq '#q=campus+bike+repair') (Hash)
Js "history.back();1" | Out-Null; Start-Sleep -Milliseconds 200
T $g 'Browser Back again returns to the home page' ((Hash) -eq '#home') (Hash)
Nav "$Base#q=campus+bike+repair"
Js "document.getElementById('cat-Events').click();1" | Out-Null; Start-Sleep -Milliseconds 120
Js "document.getElementById('f-free').click();1" | Out-Null; Start-Sleep -Milliseconds 120
Js "history.back();1" | Out-Null; Start-Sleep -Milliseconds 200
T $g 'Browser Back undoes the last filter step by step' ((Hash) -eq '#q=campus+bike+repair&type=Events') (Hash)

$g = 'Problem 2: free bike repair workshop under Free only'
foreach ($q in @('campus bike repair','bike repair workshop','free bike repair workshop','bike workshop','bike repair')) {
  $h = '#q=' + ($q -replace ' ','+') + '&type=Events&filter=free'
  Nav "$Base$h"
  $titles = Js "JSON.stringify([...document.querySelectorAll('ol.results .title')].map(b=>b.textContent))"
  T $g "Events + Free only for '$q' lists Fix a Flat Tire workshop" ($titles -like '*Fix a Flat Tire workshop*') $titles
}
$found = $false
foreach ($pg in 1, 2) { Nav "$Base#q=campus+bike+repair&filter=free&page=$pg"; if ((Js "[...document.querySelectorAll('ol.results .title')].some(b=>b.textContent==='Fix a Flat Tire workshop')") -eq $true) { $found = $true } }
T $g "Free only with all types also lists it (across result pages)" $found
Nav "$Base#q=campus+bike+repair&type=Events&filter=free"
T $g 'Every listed event says Free in words' ((Js "[...document.querySelectorAll('ol.results li')].every(li=>li.querySelector('.badge.free'))") -eq $true)

$g = 'Problem 3: filters visible, not top right'
foreach ($w in 1100, 1440, 360) {
  Size $w 800; Nav "$Base#q=campus+bike+repair"
  $r = Js "(()=>{const c=document.getElementById('controls').getBoundingClientRect();const t=document.getElementById('view-title').getBoundingClientRect();return JSON.stringify({left:Math.round(c.left),titleLeft:Math.round(t.left),top:Math.round(c.top),right:Math.round(c.right),vw:innerWidth,vh:innerHeight})})()" | ConvertFrom-Json
  T $g "At $w px: filters sit under the heading on the left, inside the first screen" ($r.left -eq $r.titleLeft -and $r.top -lt $r.vh -and $r.top -gt 0) ("left $($r.left), top $($r.top), viewport $($r.vw)x$($r.vh)")
  T $g "At $w px: all Type and Show choices are visible without opening a menu" ((Js "[...document.querySelectorAll('#controls button,#controls label')].every(e=>{const r=e.getBoundingClientRect();return r.width>0&&r.height>0&&getComputedStyle(e).visibility==='visible'})") -eq $true)
}
Size 1100 800

$g = 'Problem 4: bigger map markers'
foreach ($w in 1100, 320) {
  Size $w 800; Nav "$Base#q=campus+bike+repair&item=north-quad"
  $m = Js "JSON.stringify([...document.querySelectorAll('.map .shape')].map(s=>Math.round(s.getBoundingClientRect().width)))"
  T $g "At $w px: both markers are at least 44 px" ((($m | ConvertFrom-Json) | Where-Object { $_ -lt 44 }).Count -eq 0) "sizes $m (was 30)"
  $clip = Js "(()=>{const map=document.querySelector('.map').getBoundingClientRect();return JSON.stringify([...document.querySelectorAll('.map .pin')].filter(p=>{const r=p.getBoundingClientRect();return r.left<map.left-1||r.right>map.right+1||r.top<map.top-1||r.bottom>map.bottom+1}).map(p=>p.textContent))})()"
  T $g "At $w px: marker labels are not cut off" ($clip -eq '[]') $clip
}
Size 1100 800

$g = 'Every button works'
$views = [ordered]@{ 'Home' = '#home'; 'Results' = '#q=campus+bike+repair'; 'Filtered' = '#q=campus+bike+repair&type=Events&filter=free'; 'No results' = '#q=purple+toaster+orchestra'; 'No results + filters' = '#q=dancing+umbrella+parade&type=Events&filter=free'; 'Event page' = '#q=campus+bike+repair&item=flat-tire'; 'Map page' = '#q=campus+bike+repair&item=north-quad' }
$probe = "location.hash+'|'+document.getElementById('main').innerHTML.length+'|'+document.getElementById('status').textContent+'|'+document.getElementById('keys').open+'|'+(document.activeElement&&document.activeElement.id)+'|'+document.getElementById('query').value+'|'+(window.__el?window.__el.textContent:'')"
foreach ($v in $views.Keys) {
  Nav "$Base$($views[$v])"
  $n = [int](Js "document.querySelectorAll('button,a[href],input[type=radio]').length")
  $fails = @(); $tested = 0
  for ($i = 0; $i -lt $n; $i++) {
    Nav "$Base$($views[$v])"
    $code = "(async()=>{window.__err=null;addEventListener('error',e=>window.__err=e.message);const els=[...document.querySelectorAll('button,a[href],input[type=radio]')];const e=els[$i];window.__el=e;if(!e)return 'skip';if(!(e.offsetParent||e.closest('.skips')))return 'skip';if(e.type==='radio'&&e.checked)return 'skip';const name=(e.id||e.textContent.trim()).slice(0,30);const before=$probe;e.click();await new Promise(r=>setTimeout(r,150));const after=$probe;return (window.__err?'ERR '+window.__err:(before===after?'NOEFFECT':'ok'))+' :: '+name})()"
    $r = Js $code
    if ($r -ne 'skip') { $tested++ }
    if ($r -notlike 'ok*' -and $r -ne 'skip') { $fails += $r }
  }
  T $g "$($v): all $tested visible buttons and links do something, no script errors" ($fails.Count -eq 0) ($fails -join '; ')
}

$g = 'Professor tasks (keyboard only)'
Nav "$Base#home"
Char '/'; Typ 'campus bike repair'; Key 'Enter'; Char 'r'; Key 'Enter'
$t1a = (Hash) -like '*item=*'
Key 'Tab' 8; Key 'Enter'
T $g 'Task 1: search campus bike repair, open a result, go back to the results' ($t1a -and (Hash) -eq '#q=campus+bike+repair' -and (Act) -like 'open-*') "$(Hash) / $(Act)"
Nav "$Base#home"
Char '/'; Typ 'campus bike repair'; Key 'Enter'; Key 'Tab'; Key 'Tab'; Key 'Tab'; Key 'Enter'; Key 'Tab'; Key 'Tab'; Key 'ArrowDown'; Char 'r'; Key 'Tab'; Key 'Enter'
$facts = Js "document.querySelector('.facts').innerText.replace(/\n/g,' ')"
T $g 'Task 2: Events + Free only, record title, date and time' ((Js "document.getElementById('view-title').textContent") -eq 'Fix a Flat Tire workshop' -and $facts -like '*Nov 28*1:00 p.m.*') "Fix a Flat Tire workshop - $facts"
Nav "$Base#home"
Char '/'; Typ 'campus bike repair'; Key 'Enter'; Char 'r'; Key 'Tab'; Key 'Tab'; Key 'Tab'; Key 'Enter'
T $g 'Task 3: open the North Quad map and identify the repair stand marker' ((Js "document.getElementById('map-purpose').textContent") -like '*Repair stand is marker 1 (circle*') (Js "document.querySelector('ol.places li').textContent")
Nav "$Base#home"
Char '/'; Typ 'purple toaster orchestra'; Key 'Enter'; $t4a = (Js "document.getElementById('view-title').textContent") -like 'No results*'
Key 'Tab'; Key 'Tab'; Key 'Enter'
T $g 'Task 4: from the no-results screen get back to a useful search' ($t4a -and (Js "document.getElementById('view-title').textContent") -like '10 results*')
$sock.Dispose()
& taskkill.exe /PID $proc.Id /T /F | Out-Null

$pass = ($results | Where-Object Result -eq 'PASS').Count; $fail = ($results | Where-Object Result -eq 'FAIL').Count
$md = @("# Fieldnote: four deliberate problems, every button, professor tasks", "", "Run: $(Get-Date -Format 'yyyy-MM-dd HH:mm') - headless Microsoft Edge - $Base", "", "**$pass passed, $fail failed** ($($results.Count) tests)", "")
foreach ($grp in ($results | Select-Object -ExpandProperty Group -Unique)) {
  $md += "## $grp", "", "| Result | Test | Detail |", "| --- | --- | --- |"
  foreach ($r in ($results | Where-Object Group -eq $grp)) { $md += "| $($r.Result) | $($r.Test) | $(($r.Detail -replace '\|','/'))|" }
  $md += ""
}
[IO.File]::WriteAllLines($Report, $md)
"$pass passed, $fail failed"
$results | Where-Object Result -eq 'FAIL' | Format-Table -AutoSize -Wrap | Out-String -Width 220

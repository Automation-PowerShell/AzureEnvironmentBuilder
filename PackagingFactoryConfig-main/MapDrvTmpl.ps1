cmd.exe /C cmdkey /add:`"xxxxx.file.core.windows.net`" /user:`"Azure\xxxxx`" /pass:`"yyyyy`"
New-PSDrive -Name Z -PSProvider FileSystem -Root "\\xxxxx.file.core.windows.net\fffff" -Persist

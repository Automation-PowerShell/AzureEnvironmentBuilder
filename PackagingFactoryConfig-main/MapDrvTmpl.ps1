cmd.exe /C cmdkey /add:`"xxxx.file.core.windows.net`" /user:`"Azure\xxxx`" /pass:`"yyyy`"
New-PSDrive -Name Z -PSProvider FileSystem -Root "\\xxxx.file.core.windows.net\pkgazfiles01" -Persist

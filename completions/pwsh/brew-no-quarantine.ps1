# powershell completion for brew-no-quarantine

if (Get-Command Register-ArgumentCompleter -ErrorAction SilentlyContinue) {
	Register-ArgumentCompleter -Native -CommandName brew-no-quarantine -ScriptBlock {
		param($wordToComplete, $commandAst, $cursorPosition)

		if (Get-Command brew -ErrorAction SilentlyContinue) {
			$completer = Get-ArgumentCompleter -Native -CommandName brew
			if ($completer) {
				return &$completer.ScriptBlock $wordToComplete $commandAst $cursorPosition
			}
		}
		return @()
	}
}

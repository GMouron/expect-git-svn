# expect-git-svn
Trying to replicate `expect` for piloting `git svn` on Windows

## Usage

`.\expect-like.ps1 -repoUrl "https://my.svn.server/svn/project" -username "test" -password "test" -certificateAcceptResponse p`

You can optionnaly indicate a destination folder with `-destination "C:\go\to\this\folder"`.

You can also use the switch `-outputStdout` if you wish to print the standard outpit of the `git svn` command.
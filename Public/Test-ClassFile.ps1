Function Test-ClassFile() {
    Import-Module "$Script:ClassDir\Book.ps1"



    [Book]::New('Eye of the World','Robert Jordan')
}
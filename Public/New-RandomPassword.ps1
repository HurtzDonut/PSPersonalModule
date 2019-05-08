    <#
        .SYNOPSIS
            Generates a specified number of passwords with random characters, of a specifed length.
        .DESCRIPTION
            Uses an array of [Char] values to generate a random password(s) or a given length.

            Then verifies that the generated password is not:
                * All Numbers
                * All Letters
                * Only Letters and Numbers
            
            Also verifies that the generated password contains at least:
                * 1 Number
                * 1 Uppercase Letter
                * 1 Lowercase Letter
                * 1 Special Character

            And is 10-20 chars in length.
        .EXAMPLE
            PS C:\> New-RandomPassword
            4^/(:eJAzGN

            Genrates 1 random password that is 11 chars in length.
        .EXAMPLE
            PS C:\> New-RandomPassword -NumberToGenerate 3 -PWLength 14
            9rA@v>1Ul\Dt0B
            _#8n$pqyF?^kb4
            y/1xKrFmJ?_O4U

            Genrates 3 random passwords that are 14 chars in length.
        .INPUTS
            System.Int32
        .OUTPUTS
            System.String
        .NOTES
            Auhtor :    Jacob C Allen (JCA)
            Created:    1/18/2019
            Modified:   3/17/2019
            Version:    1.3
    #>
    Function New-RandomPassword {
        [CmdLetBinding()]
        Param (
            [Parameter(Position=0)]
            [ValidateRange(1,10)]
                [Int]$NumberToGenerate = 1,

            [Parameter(Position=1)]
            [ValidateRange(10,20)]
                [Int]$PWLength = 11
        )
        
        Begin {
            $PwList = [System.Collections.ArrayList]::New()

            $NewPassChars = @(#  [SPACE] !
                # [SPACE] !
                    [char[]]([char]32..[char]33) +
                #  # $ % &
                    [char[]]([char]35..[char]38) +
                #  ( ) * + , - . / 0 1 2 3 4 5 6 7 8 9 : ; < = > ? @ A B C D E F G H I J K L M N O P Q R S T U V W X Y Z [ \ ] ^ _
                    [char[]]([char]40..[char]95) +
                #  a b c d e f g h i j k l m n o p q r s t u v w x y z
                    ([char[]]([char]97..[char]122))
            )
        } # Begin Block
        
        Process {
            0..($NumberToGenerate-1) | ForEach-Object {
                Do {
                    $NewP = (Get-Random -InputObject $NewPassChars -Count $PWLength) -Join '' 

                    # Ensures the password is not: All Numbers, All Letters, Only Letters and Numbers
                    # Ensures the password contains at least: 1 Number, 1 Uppercase Letter, 1 Lowercase Letter, 1 Special Character and is 10-20 characters long
                } Until ($NewP -CMatch '(?!^[0-9]*$)(?!^[a-zA-Z]*$)(?!^[a-zA-Z0-9]*$)^([a-zA-Z0-9()*+,\-\.\/:;<=>?@\[\\\]^_#$%& ]{10,20})$')
                
                If ($NewP -Match '\s') {
                    $Index = $NewP.IndexOf([Char]32)
                    $NewP += ('  <-- Character [{0}] is [SPACE]' -F $Index)
                }

                [Void]$PwList.Add($NewP)
            }
        } # Process Block

        End {
            $PwList
        } # End Block
    } # Function New-RandomPassword
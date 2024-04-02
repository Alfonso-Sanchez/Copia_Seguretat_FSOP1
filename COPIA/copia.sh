#!/bin/bash

name="Copia.tgz" #Name of the .tar file
tempDir="temp" #Temporary dir for testing and checking dates
fullpath="/home/milax/COPIA"

# Use message
use="Us: $(basename "$0") [-h] [-K]/[-D] [arxius/directoris]

On:
    -h Mostra aquest missatge
    -K Comprova si fitxer esta al comprimit, si esta, afegeix el nou amb la data d'ahui.
    -D DryRun, no fará res, sols mostra per pantalla les execucions que faría el script.

    Exemples:

    > Afegir arxius mes nous que les de la copia
    $(tput setaf 1) $(basename "$0")$(tput sgr0) $(tput setaf 5)-K $(tput sgr0)$(tput setaf 6)arxiu_3 arxiu_2 dir_1 $(tput sgr0)
    
    > Mostrar tot el que fará el script sense modifcar res
    $(tput setaf 1) $(basename "$0")$(tput sgr0) $(tput setaf 5)-D $(tput sgr0)$(tput setaf 6)dir_1 arxiu_4 $(tput sgr0)
    
    > Generar una copia de seguretat si no existeix Scap o afegir a la copia actual si existeix
    $(tput setaf 1) $(basename "$0")$(tput sgr0)$(tput setaf 6) arxiu_3 arxiu_4 arxiu_5 dir_3 $(tput sgr0)
    
"


# Functions developed

#Compress files checking the args, if is -D only show how is gonna do it. If is -K checks and changes name to the recent date. 
function compressFiles() {
    if [ ! -e "$fullpath/$name" ]; then #If the copy doesnt exists, create it
        if [ $dryRun -eq 1 ]; then
             "$(tput setaf 1)Se ha creat el archiu $name amb la llista generada!!$(tput sgr0)"
        else
            tar cfz $fullpath/$name $dirList $fileList
        fi
    else
        if [ $dryRun -eq 1 ]; then
            echo "$(tput setaf 1)Se ha afegit la llista generada al archiu $name!!$(tput sgr0)"
        elif [ $isK -eq 1 ]; then
            mkdir $fullpath/$tempDir
            tar xzf $fullpath/$name -C $fullpath/$tempDir
            for file in $fileList; do
                fileWithDate="${file}.$(date +%Y%m%d)"
                mod_time_temp="$(stat -c %Y "$fullpath/$tempDir/$file")"
                mod_time_original="$(stat -c %Y "$file")"
                if [ "$mod_time_original" -gt "$mod_time_temp" ]; then
                    cp $file $fullpath/$tempDir/$fileWithDate
                fi
            done
            # We compress files again
            rm -f $fullpath/$name
            cd $fullpath/$tempDir
            tar cfz ../$name * #verify
            cd ..
            rm -R $fullpath/$tempDir
        else
            #Uncompress files, make changes and compress again
            mkdir $fullpath/$tempDir
            tar xzf $fullpath/$name -C $fullpath/$tempDir
            for dir in $dirList; do
                cp -r $dir $fullpath/$tempDir/$dir
            done
            for file in $fileList; do
                cp $file $fullpath/$tempDir/$file
            done
            rm -f $name
            cd $fullpath/$tempDir
            pwd
            tar cfz ../$name *
            cd ..
            rm -R $fullpath/$tempDir
        fi
    fi
}
#Generate a list of files and dirs passed by args. 
function generateList() {
    dirList=''
    fileList=''

    for input in $argsList; do
        if [ -d "$input" ]; then
            if [ $dryRun -eq 1 ]; then
                echo "$(tput setaf 1)Afegint$(tput sgr0) > $(tput setaf 7)(d)$(tput sgr0)$(tput setaf 5)$input$(tput sgr0) a $(tput setaf 6)llista directoris.$(tput sgr0)"
            else 
                dirList="$dirList $input"
            fi
        else
            if [ $dryRun -eq 1 ]; then
                echo "$(tput setaf 1)Afegint$(tput sgr0) > $(tput setaf 7)(f)$(tput sgr0)$(tput setaf 5)$input$(tput sgr0) a $(tput setaf 6)llista fitxers$(tput sgr0)"
            else
                fileList="$fileList $input"
            fi
        fi
    done
}

function main() {
    if [ $numberArgs -ge 1 ]; then
     	if [ ! -e $fullpath ]; then
     	   mkdir $fullpath
     	   generateList
           compressFiles
     	else 
          generateList
          compressFiles
        fi
        exit 0
    elif [ $numberArgs -eq 0 ]; then
        echo "$use"
        exit 1
    fi
}

#Boolean vars for checking args 
dryRun=0
isK=0

#Check the args, for -h -K -D options
while getopts 'hKD' option; do
    case "$option" in
        h)  echo "$use"
            exit
            ;;
        K)  isK=1
            shift
            numberArgs=$#
            argsList=$@
            main
            exit
            ;;
        D)  dryRun=1
            shift
            numberArgs=$#
            argsList=$@
            main
            exit
            ;;
        \?) #A beauty error message
        echo "$(tput setaf 1)**********************************$(tput sgr0)"
        echo "$(tput setaf 2)           /\ /|           $(tput sgr0)"
        echo "$(tput setaf 3)          |||| |           $(tput sgr0)"
        echo "$(tput setaf 4)           \ | \           $(tput sgr0)"
        echo "$(tput setaf 5)       _ _ /  ()()    ¡¡¡ ERROR !!!     $(tput sgr0)"
        echo "$(tput setaf 6)     /    \   =>*<=         $(tput sgr0)"
        echo "$(tput setaf 7)   /|      \   /|           $(tput sgr0)"
        echo "$(tput setaf 8)   \|     /__| |           $(tput sgr0)"
        echo "$(tput setaf 9)     \_____) \__)           $(tput sgr0)"
        echo "$(tput setaf 1)**********************************$(tput sgr0)"
        echo ""
        echo "$use" >&2
        exit 1
        ;;
    esac
done

#if no errors or arguments go to normal execution
numberArgs=$#
argsList=$@
main




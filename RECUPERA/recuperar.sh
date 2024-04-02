#!/bin/bash

# Funció per verificar si existeix el fitxer o el directori
function existeix() {
  if [ -e "$1" ]; then
    return 0
  else
    return 1
  fi
}

# Funció per a descomprimir temporalment el directori
function descomprimir_temp() {
    directori_temporal=$(mktemp -d)
    tar -xzf "$1" -C "$directori_temporal" || { echo "ERROR al descomprimir l'arxiu."; exit 1; }
}

function recuperar() {
  # Verifiquem si estem en mode Dry Run o creem la carpeta destí
  if [ "$dryRun" = false ]; then
    mkdir -p "$directori_desti" || { echo "Error en crear la carpeta destí."; exit 1; }
  else
    echo "Creant carpeta DESTÍ amb el nom $directori_desti ..."
  fi

  # Descomprimim l'arxiu al directori temporal
  descomprimir_temp "${1}"

  # Recorrem tots els arxius i carpetes del directori temporal
  find "$directori_temporal" -mindepth 1 -print0 | while IFS= read -r -d $'\0' ruta_final; do
    nombre_archivo=$(basename "$ruta_final")

    # Comprovem si coincideix amb algun paràmetre, excepte l'últim
    for ((i = 1; i < $#; i++)); do
      if [ "$nombre_archivo" == "${!i}" ]; then
        # Si coincideix i és un arxiu, el copiem al directori destí
        if [ -f "$ruta_final" ]; then
          if [ "$ruta_final" != "${directori_temporal}/${1}" ]; then
            if [ "$dryRun" = true ]; then
              echo "Copiant $ruta_final a $directori_desti..."
            else
              cp "$ruta_final" "$directori_desti" || { echo "Error en copiar $ruta_final a $directori_desti."; exit 1; }
            fi
          fi
        fi

        # Busquem arxius amb el mateix nom base però amb qualsevol extensió després del punt
        nombre_base="${!i%.*}"
        find "$directori_temporal" -maxdepth 1 -type f -name "${nombre_base}.*" ! -name "${!i}" -print0 | while IFS= read -r -d $'\0' archivo_ext; do
          if [ "$archivo_ext" != "$ruta_final" ]; then
            if [ "$dryRun" = true ]; then
              echo "Copiant $archivo_ext a $directori_desti..."
            else
              cp "$archivo_ext" "$directori_desti" || { echo "Error en copiar $archivo_ext a $directori_desti."; exit 1; }
            fi
          fi
        done
      fi
    done

    # Verifiquem si és un directori que coincideix amb un paràmetre
    if [ -d "$ruta_final" ]; then
      for ((i = 1; i < $#; i++)); do
        if [ "${ruta_final##*/}" == "${!i}" ]; then
          if [ "$dryRun" = true ]; then
            echo "Copiant directori $ruta_final a $directori_desti..."
          else
            cp -r "$ruta_final" "$directori_desti/${!i}" || { echo "Error en copiar $ruta_final a $directori_desti."; exit 1; }
          fi
        fi
      done
    fi

  done

  # Si no estem en mode Dry Run, eliminem el directori temporal
  if [ "$dryRun" = false ]; then
    rm -rf "$directori_temporal"
  fi
}

# Inicialitzem la variable que ens indica si recuperem informació o no
dryRun=false
directori_temporal=""
directori_desti="${!#}"

#COMENÇAMENT DEL MAIN

if [ $# -lt 3 ]; then
        echo "ERROR: Paràmetres insuficients !!!"
        echo "$(tput setaf 1)*******************************$(tput sgr0)"
        echo ""
        echo "$(tput setaf 2)           /\ /|           $(tput sgr0)"
        echo "$(tput setaf 3)          |||| |           $(tput sgr0)"
        echo "$(tput setaf 4)           \ | \           $(tput sgr0)"
        echo "$(tput setaf 5)       _ _ /  ()() ERROR        $(tput sgr0)"
        echo "$(tput setaf 6)     /    \   =>*<=         $(tput sgr0)"
        echo "$(tput setaf 7)   /|      \   /|           $(tput sgr0)"
        echo "$(tput setaf 8)   \|     /__| |           $(tput sgr0)"
        echo "$(tput setaf 9)     \_____) \__)           $(tput sgr0)"
        echo "$(tput setaf 1)*******************************$(tput sgr0)"
        mostrar_menu
        exit 1;
else

    # Comprovem si s'ha introduit un "-D" com a primer parametre
    if [ "$1" == "-D" ]; then
        dryRun=true
        echo "Executant en mode de simulació (Dry Run)..."
        # Eliminem el primer parametre de la llista (en aquest cas la D)
        shift
    fi

    # Comprovació si el "fitxer.tgz" existeix
    if existeix "$1"; then

        # Descomprimim l'arxiu
        descomprimir_temp "$1"
        
        recuperar "$@"

    else
        echo "El fitxer comprimit (format .tgz o .tar.gz) NO EXISTEIX !!!"
        echo "$(tput setaf 1)*********    ERROR    *********$(tput sgr0)"
        echo ""
        echo "$(tput setaf 2)           /\ /|           $(tput sgr0)"
        echo "$(tput setaf 3)          |||| |           $(tput sgr0)"
        echo "$(tput setaf 4)           \ | \           $(tput sgr0)"
        echo "$(tput setaf 5)       _ _ /  ()() ERROR        $(tput sgr0)"
        echo "$(tput setaf 6)     /    \   =>*<=         $(tput sgr0)"
        echo "$(tput setaf 7)   /|      \   /|           $(tput sgr0)"
        echo "$(tput setaf 8)   \|     /__| |           $(tput sgr0)"
        echo "$(tput setaf 9)     \_____) \__)           $(tput sgr0)"
        echo "$(tput setaf 1)*******************************$(tput sgr0)"
        mostrar_menu
        exit 1;
    fi

fi

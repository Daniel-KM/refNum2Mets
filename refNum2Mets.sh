#!/bin/sh
#
# Convertit tous les fichiers refNum d'un dossier en Mets via xslt Saxon-HE.
#
# - Les fichiers originaux sont conservés.
# - Le hash de tous les fichiers est calculé, ce qui peut être long.
# - Les noms de fichiers ne doivent pas contenir d'espace (problème dans
# l'extraction des tailles de fichiers).
#
# Les noms de fichiers doivent correspondre à ceux de refNum2Mets_config.xml.
#
# Utilise :
# - xmllint
# - saxon-he
#
# Auteur Daniel Berthereau <daniel.berthereau@mines-paristech.fr>
# Copyright Daniel Berthereau, 2015-09-21
# Licence CeCILL v2.1
#
# Commande :
# refNum2Mets.sh dossier

dossier=$1

preparehash='true'
reindente='true'

# Valeurs par défaut.
if [ "$dossier" = '' ]
then
    dossier=$(pwd)
fi

# Si ods est présent, on sauve ses métadonnées en xml, sinon on prend le xml.
filemetadata='fichiers_metadata.ods'
filemetadataxml='fichiers_metadata.xml'
filehashs='fichiers_hashs.txt'
filesizes='fichiers_tailles.txt'

arks='arks.txt'

# Directory du script
# Absolute path to this script, e.g. /home/user/bin/foo.sh
SCRIPT=$(readlink -f "$0")
# Absolute path this script is in, thus /home/user/bin
SCRIPTPATH=$(dirname "$SCRIPT")

xslpath="$SCRIPTPATH/refNum2Mets.xsl"
xslidentitypath="$SCRIPTPATH/identity.xsl"

echo Traitement du dossier \"$dossier\" via \"$xslpath\".
echo

# Traitement du dossier
file -i $dossier/* | grep --ignore-case 'application/xml' | awk -F':' '{ print $1 }' | while read file
do
    # Vérification rapide si c'est un fichier refNum (sans validation avancée).
    xmlroot=$(xmllint --xpath 'local-name(/*)' "$file")
    if [ "$xmlroot" != 'refNum' ]
    then
        continue
    fi

    dirname=$(dirname "$file")
    filename=$(basename "$file")
    name="${filename%.*}"
    extension="${filename##*.}"

    # Vérifie s'il y a une double extension (.refnum.xml).
    if [ "${name##*.}" = 'refnum' ]
    then
        name="${name%.*}"
    fi

    # Prépare le nom du fichier mets.
    metsfilename="$name.mets.xml"
    metspath="$dirname/$metsfilename"

    # Compte le nombre de fichiers pour info.
    nombrefichiers=$(find $dirname -follow -type f | wc -l)
    taillefichiers=$(du -sh | cut -f 1)

    echo $filename '=>' $metsfilename \($nombrefichiers fichiers, $taillefichiers\)

    # Extraction des métadonnées si besoin.
    if [ -f "$filemetadata" ]
    then
        echo '  ' Utilisation des métadonnées de "$filemetadata" décompressées dans "$filemetadataxml".
        unzip -p "$filemetadata" content.xml > "$filemetadataxml"
    else
        if [ -f "$filemetadataxml" ]
        then
            echo '  ' Utilisation des métadonnées de "$filemetadataxml".
        else
            echo '  ' Pas de métadonnées pour les fichiers.
            metadatapath=""
        fi
    fi

    # Préparation des taille des fichiers du dossier courant.
    taillepath="$dirname/$filesizes"
    find . -type f -print0 | xargs -0 stat --format '%n %s' | cut -sd / -f 2- | sort | awk '{print $2"  "$1}' > "$taillepath"

    # Préparation des hashs des fichiers du dossier courant.
    if [ "$preparehash" = 'true' ]
    then
        echo '  ' Calcul des hash sha1 des fichiers du dossier...

        hashpath="$dirname/$filehashs"
        find . -type f | cut -sd / -f 2- | sort | xargs sha1sum > "$hashpath"
    fi

    # Commande pour Debian 8.
    CLASSPATH=/usr/share/java/Saxon-HE.jar java net.sf.saxon.Transform -ext:on -versionmsg:off -s:"$file" -xsl:"$xslpath" -o:"$metspath"

    # Améliore l'indentation, ce qui est impossible avec la version libre de
    # saxon.
    if [ "$reindente" = 'true' ]
    then
        xmllint --format --recover --output "$metspath" "$metspath"
    fi

done

echo
echo Traitement terminé.

exit 0

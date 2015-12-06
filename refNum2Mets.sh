#!/bin/sh
#
# Convertit tous les fichiers refNum d'un dossier en Mets via xslt Saxon-HE.
#
# - Les métadonnées peuvent se trouver dans des tables ODS ou en xml.
# - Les fichiers originaux sont conservés sans modification.
# - Le hash de tous les fichiers est calculé, ce qui peut être long.
# - Les noms de fichiers ne doivent pas contenir d'espace (problème dans
# l'extraction des tailles de fichiers).
#
# Les noms de fichiers doivent correspondre à ceux de refNum2Mets_config.xml.
# Les dossiers doivent correspondre à ceux de refNum2Mets_codes.xml (<objetAssocie>).
# Recommandé : "master" pour les fichiers master (et non "PNG" ou "TIFF") et
# "ocr" pour les fichiers d'ocr.
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

prepareTailles='true'
prepareHashs='true'
reindente='true'
supprimeFichiersIntermediaires='false'

# Vérifie l'outil xsl.
if [ -r '/etc/debian_version' ]; then
    distro='Debian'
elif [ -r '/etc/redhat-release' ]; then
    distro='Red Hat'
    echo 'Ne pas tenir compte de la remarque éventuelle "Cannot find CatalogManager.properties".'
    echo
else
    echo Impossible de déterminer la ligne de commande pour convertir le xml.
    exit 1;
fi

# Valeurs par défaut.
if [ "$dossier" = '' ]
then
    dossier=$(pwd)
fi

# Si ods est présent, on sauve ses métadonnées en xml, sinon on prend le xml.
documentsMetadata='documents_metadata.ods'
documentsMetadataXml='documents_metadata.xml'
fichiersMetadata='fichiers_metadata.ods'
fichiersMetadataXml='fichiers_metadata.xml'
fichiersHashs='fichiers_hashs.txt'
fichiersTailles='fichiers_tailles.txt'
# Non utilisé ici.
#fichierArks='documents_arks.txt'

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
    nombreFichiers=$(find $dirname -follow -type f | wc -l)
    tailleFichiers=$(du -sh | cut -f 1)

    echo $filename '=>' $metsfilename \($nombreFichiers fichiers, $tailleFichiers\)

    # Info sur les fichiers.
    subdircount=$(find "$dirname" -maxdepth 1 -type d | wc -l)
    if [ $subdircount -eq 1 ]; then
        echo '   * Attention : Pas de sous-dossier : les liens vers les fichiers devront être vérifiés.'
    elif [ $subdircount -gt 1 ] && [ ! -d 'master' ]; then
        echo '   * Attention : Pas de sous-dossier "master". Les hash et tailles ne seront pas ajoutés.'
        echo '   *' Vérifier si la configuration est bien adaptée aux noms de sous-dossiers spécifiques.
    fi

    # Extraction des notices des documents si besoin.
    if [ -f "$documentsMetadata" ]
    then
        noticespath="$dirname/$documentsMetadataXml"
        echo '  ' Utilisation des notices de "$documentsMetadata" décompressées dans "$noticespath".
        unzip -p "$documentsMetadata" content.xml > "$noticespath"
    else
        if [ -f "$documentsMetadataXml" ]
        then
            echo '  ' Utilisation des notices de "$documentsMetadataXml".
            noticespath="$dirname/$documentsMetadataXml"
        else
            echo '  ' Pas de notices pour les documents.
            noticespath=""
        fi
    fi

    # Extraction des métadonnées des fichiers si besoin.
    if [ -f "$fichiersMetadata" ]
    then
        metadatapath="$dirname/$fichiersMetadataXml"
        echo '  ' Utilisation des métadonnées de "$fichiersMetadata" décompressées dans "$metadatapath".
        unzip -p "$fichiersMetadata" content.xml > "$metadatapath"
    else
        if [ -f "$fichiersMetadataXml" ]
        then
            echo '  ' Utilisation des métadonnées de "$fichiersMetadataXml".
            metadatapath="$dirname/$fichiersMetadataXml"
        else
            echo '  ' Pas de métadonnées pour les fichiers.
            metadatapath=""
        fi
    fi

    # Préparation des tailles des fichiers du dossier courant.
    if [ "$prepareTailles" = 'true' ]
    then
        echo '  ' Calcul des tailles des fichiers du dossier...
        taillespath="$dirname/$fichiersTailles"
        find . -type f -print0 | xargs -0 stat --format '%n  %s' | cut -sd / -f 2- | sort > "$taillespath"
    fi

    # Préparation des hashs des fichiers du dossier courant.
    if [ "$prepareHashs" = 'true' ]
    then
        echo '  ' Calcul des hash sha1 des fichiers du dossier...
        hashspath="$dirname/$fichiersHashs"
        find . -type f | cut -sd / -f 2- | xargs sha1sum | awk '{print $2"  "$1}' | sort > "$hashspath"
    fi

    if [ "$distro" = 'Debian' ]
    then
        # Debien 6 avec Saxon-B.
        # saxonb-xslt -ext:on -versionmsg:off -s:"$file" -xsl:"$xslpath" -o:"$metspath"

        # Commande pour Debian 8 avec Saxon-HE.
        CLASSPATH=/usr/share/java/Saxon-HE.jar java net.sf.saxon.Transform -ext:on -versionmsg:off -s:"$file" -xsl:"$xslpath" -o:"$metspath"
    elif [ "$distro" = 'Red Hat' ]
    then
        saxon -ext:on -versionmsg:off -s:"$file" -xsl:"$xslpath" -o:"$metspath"
    else
        exit 1;
    fi

    # Améliore l'indentation, ce qui est impossible avec la version libre de
    # saxon.
    if [ "$reindente" = 'true' ]
    then
        xmllint --format --recover --output "$metspath" "$metspath"
    fi

    # Suppression éventuelle des fichiers intermédiaires.
    if [ "$supprimeFichiersIntermediaires" = 'true' ]
    then
        echo '  ' Suppression des fichiers intermédaires créés par ce script.
        if [ -f "$documentsMetadata" ]
        then
            rm -f "$noticespath"
        fi
        if [ -f "$fichiersMetadata" ]
        then
            rm -f "$metadatapath"
        fi
        if [ "$prepareTailles" = 'true' ]
        then
            rm -f "$taillespath"
        fi
        if [ "$prepareHashs" = 'true' ]
        then
            rm -f "$hashspath"
        fi
    fi

done

echo
echo Traitement terminé.

exit 0

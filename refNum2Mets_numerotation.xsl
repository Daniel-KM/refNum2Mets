<?xml version="1.0" encoding="UTF-8"?>
<!--
Description : Convertit un fichier refNum en Mets.
Version : 20150921
Auteur : Daniel Berthereau pour l'École des Mines de Paris [http://bib.mines-paristech.fr]

Cette feuille dépend de refNum2Mets.xsl.
Elle permet de définir les numéros des identifiants des sections et sous-sections du Mets.

@see http://bibnum.bnf.fr/ns/refNum.xsd
@see https://github.com/Daniel-KM/refNum2Mets
@copyright Daniel Berthereau, 2015
@license http://www.cecill.info/licences/Licence_CeCILL_V2.1-fr.html
-->

<xsl:stylesheet version="2.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:fn="http://www.w3.org/2005/xpath-functions"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:r2m="refNum2Mets"
    xmlns:refNum="http://bibnum.bnf.fr/ns/refNum"
    xmlns:detailsOperation="http://bibnum.bnf.fr/ns/detailsOperation"

    exclude-result-prefixes="
        xsl fn xs r2m refNum detailsOperation
        ">

    <xsl:output method="xml" indent="yes" encoding="UTF-8"/>

    <xsl:strip-space elements="*"/>

    <!-- Paramètres -->

    <!-- Choix du profil d'options. -->
    <xsl:param name="configuration">refNum2Mets_config.xml</xsl:param>

    <!-- Constantes. -->

    <!-- Liste des paramètres du fichier de configuration. -->
    <xsl:variable name="parametres"
        select="document($configuration)/XMLlist"/>
    <xsl:variable name="profil"
        select="$parametres/profil[@nom = ../formats/profil_mets[@utiliser = 'true'][1]/@nom]" />

    <!-- Quelques valeurs pour faciliter la numérotation des index. -->
    <!-- Le nombre de fichiers est celui des seuls masters et non des objets associés.
    L'élement "nombreImages" n'est pas utilisé, car il n'y a pas que des images. -->
    <xsl:variable name="nombreFichiers"
        select="count(/refNum:refNum/refNum:document/refNum:structure/refNum:vueObjet/refNum:*[name() = 'texte' or name() = 'image' or name() = 'audio'])" />
    <xsl:variable name="nombreObjetsAssocies"
        select="count(/refNum:refNum/refNum:document/refNum:production/refNum:objetAssocie)" />
    <xsl:variable name="objetsAssocies"
        select="/refNum:refNum/refNum:document/refNum:production/refNum:objetAssocie" />
    <!-- Totaux utilisés pour établir les numéros d'identifiants. -->
    <xsl:variable name="nombreOperations"
        select="count(/refNum:refNum/refNum:document/refNum:production/refNum:historique/refNum:traitement/refNum:operation)" />
    <xsl:variable name="nombreCommentairesStructure"
        select="count(/refNum:refNum/refNum:document/refNum:structure//refNum:commentaire)" />
    <xsl:variable name="configNombreAMD" select="
        number($profil/section/AdministrativeMetadataSection/techMD/@remplir = 'true'
            and $profil/section/AdministrativeMetadataSection/techMD/meta/@remplir = 'true')
        + number($profil/section/AdministrativeMetadataSection/techMD/@remplir = 'true'
            and $profil/section/AdministrativeMetadataSection/techMD/info/@remplir = 'true')
        + number($profil/section/AdministrativeMetadataSection/digiprovMD/@remplir = 'true'
            and $profil/section/AdministrativeMetadataSection/digiprovMD/valide/@remplir = 'true')
        " />

    <!-- ==============================================================
    Fonctions de numérorations des identifiants Mets
    =============================================================== -->

    <xsl:function name="r2m:genereIndexDmd">
        <!-- Numéro du fichier ou de l'opération. -->
        <xsl:param name="numero" />

        <!-- Les deux premiers DMD sont la notice du périodique éventuel, puis la
        notice principale de l'item. -->
        <xsl:value-of select="
            $numero
            + number($parametres/periodique/@remplir = 'true')
            + number($profil/section/DescriptiveMetadataSection/@remplir = 'true')
            " />
    </xsl:function>

    <!-- Retourne l'index d'une sous-section de la section Administrative Metadata.
    Les identifiants n'ont pas de forme définie. Dans le profil BnF, ils doivent
    commencer par "AMD.". Dans d'autres profils, le préfixe est lié au fichier ou
    à la sous-section. Généralement, c'est un simple numéro incrémenté lors de
    chaque opération, mais ce peut être aussi un code sans signification
    particulière, puisqu'il sert seulement pour les références internes du Mets.
    S'agissant d'une conversion, le numéro est incrémenté selon un ordre simplifié :
    - la source (unique) est le numéro 1 ;
    - l'historique de production (opérations 2 à 4 dans l'exemple)
    - puis les numéros de fichiers par série (master, puis chaque série d'objets associés) ;
    - puis les opérations de production éventuelles,
    - puis les droits (interdits dans le profil Mets SIP BnF) ;
    Ainsi, les premiers numéros sont les mêmes que pour les numéros des
    métadonnées de description. Si une sous-section n'est pas activée dans un
    profil particulier, l'incrémentation n'en tient pas compte. À cet effet, la
    fonction peut être utilisée de manière récursive.
    Sinon, utiliser "<xsl:number/>".
    -->
    <xsl:function name="r2m:genereIndexAmd">
        <xsl:param name="sousSection" />
        <!-- Numéro du fichier ou de l'opération ou du commentaire. -->
        <xsl:param name="numero" />
        <!-- L'objet associé sert uniquement à déterminer le techMD. -->
        <!-- refNum n'interdit pas d'avoir plusieurs fois le même objet associé,
        mais cela n'a pas de sens. On peut donc récupérer le numéro en cours à
        partir du nom de cet objet. -->
        <xsl:param name="objetAssocie" />

        <xsl:choose>
            <!-- Format du document. -->
            <xsl:when test="$sousSection = 'sourceMD'">
                <!-- Toujours "1" quand c'est actif, sinon "0". -->
                <xsl:value-of select="number($profil/section/AdministrativeMetadataSection/sourceMD/@remplir = 'true')" />
            </xsl:when>

            <!-- Historique général (production). -->
            <xsl:when test="$sousSection = 'digiprovMD'">
                <xsl:value-of select="
                    r2m:genereIndexAmd('sourceMD', 0, '')
                    + (number($profil/section/AdministrativeMetadataSection/digiprovMD/@remplir = 'true')
                        * $numero
                    )
                    " />
            </xsl:when>

            <!-- Historique de la structure (commentaires). -->
            <xsl:when test="$sousSection = 'digiprovMD_structure'">
                <xsl:value-of select="
                    r2m:genereIndexAmd('digiprovMD', $nombreOperations, '')
                    + (number($profil/section/AdministrativeMetadataSection/digiprovMD/@remplir = 'true')
                        * $numero
                    )
                    " />
            </xsl:when>

            <!-- Spar (début). -->
            <xsl:when test="$sousSection = 'spar_creation'">
                <xsl:value-of select="
                    r2m:genereIndexAmd('digiprovMD_structure', $nombreCommentairesStructure, '')
                    + number($profil/section/AdministrativeMetadataSection/spar/@remplir = 'true')
                    " />
            </xsl:when>

            <xsl:when test="$sousSection = 'spar_objets'">
                <xsl:value-of select="
                    r2m:genereIndexAmd('spar_creation', 0, '')
                    + (number($profil/section/AdministrativeMetadataSection/spar/@remplir = 'true')
                        * (r2m:indexObjetAssocie($objetAssocie) + 1)
                        )
                    " />
            </xsl:when>

            <xsl:when test="$sousSection = 'spar_preingest'">
                <xsl:value-of select="
                    r2m:genereIndexAmd('spar_objets', 0, string($objetsAssocies[position() = last()]))
                    + number($profil/section/AdministrativeMetadataSection/spar/@remplir = 'true')
                    " />
            </xsl:when>

            <xsl:when test="$sousSection = 'spar_techMD'">
                <xsl:value-of select="
                    r2m:genereIndexAmd('spar_preingest', 0, '')
                    + number($profil/section/AdministrativeMetadataSection/spar/@remplir = 'true')
                    " />
            </xsl:when>

            <!-- Boucle meta / info / validité -->
            <xsl:when test="$sousSection = 'techMD_meta'">
                <xsl:value-of select="
                    r2m:genereIndexAmd('spar_techMD', 0, '')
                    + (number($profil/section/AdministrativeMetadataSection/techMD/@remplir = 'true'
                        and $profil/section/AdministrativeMetadataSection/techMD/meta/@remplir = 'true')
                        * ($nombreFichiers * $configNombreAMD * r2m:indexObjetAssocie($objetAssocie)
                            + (($numero - 1) * $configNombreAMD)
                            + 1
                        )
                    )
                    " />
            </xsl:when>

            <xsl:when test="$sousSection = 'techMD_info'">
                <xsl:value-of select="
                    r2m:genereIndexAmd('spar_techMD', 0, '')
                    + (number($profil/section/AdministrativeMetadataSection/techMD/@remplir = 'true'
                        and $profil/section/AdministrativeMetadataSection/techMD/info/@remplir = 'true')
                        * ($nombreFichiers * $configNombreAMD * r2m:indexObjetAssocie($objetAssocie)
                            + (($numero - 1) * $configNombreAMD)
                            + 1
                            + number($profil/section/AdministrativeMetadataSection/techMD/@remplir = 'true'
                        and $profil/section/AdministrativeMetadataSection/techMD/meta/@remplir = 'true')
                        )
                    )
                    " />
            </xsl:when>

            <xsl:when test="$sousSection = 'digiprovMD_valide'">
                <xsl:value-of select="
                    r2m:genereIndexAmd('spar_techMD', 0, '')
                    + (number($profil/section/AdministrativeMetadataSection/digiprovMD/@remplir = 'true'
                        and $profil/section/AdministrativeMetadataSection/digiprovMD/valide/@remplir = 'true')
                        * ($nombreFichiers * $configNombreAMD * r2m:indexObjetAssocie($objetAssocie)
                            + (($numero - 1) * $configNombreAMD)
                            + 1
                            + $configNombreAMD - 1
                        )
                    )
                    " />
            </xsl:when>

            <!-- Spar fin. -->
            <xsl:when test="$sousSection = 'spar_fin'">
                <xsl:value-of select="
                    r2m:genereIndexAmd('digiprovMD_valide', $nombreFichiers, string($objetsAssocies[position() = last()]))
                    + (number($profil/section/AdministrativeMetadataSection/spar/@remplir = 'true')
                        * $numero
                        )
                    " />
            </xsl:when>

            <!-- Actuellement, pour un seul droit. -->
            <xsl:when test="$sousSection = 'rightsMD'">
                <!-- TODO Actualiser le nombre en fonction du nombre de spar fin. -->
                <xsl:value-of select="
                    r2m:genereIndexAmd('spar_fin', $profil/section/AdministrativeMetadataSection/spar/@fin + number($parametres/periodique/@remplir = 'true'), '')
                    + ($nombreFichiers * $configNombreAMD * $nombreObjetsAssocies)
                    + number($profil/section/AdministrativeMetadataSection/rightsMD/@remplir = 'true')
                    " />
            </xsl:when>
        </xsl:choose>
    </xsl:function>

    <!-- Détermine l'index de l'objet associé. -->
    <!-- TODO Utiliser "key". -->
    <xsl:function name="r2m:indexObjetAssocie">
        <xsl:param name="objetAssocie" />

        <xsl:choose>
            <xsl:when test="$objetsAssocies[text() = $objetAssocie]">
                <xsl:value-of select="count($objetsAssocies[text() = $objetAssocie]/preceding-sibling::refNum:objetAssocie) + 1" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="number(0)" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

</xsl:stylesheet>


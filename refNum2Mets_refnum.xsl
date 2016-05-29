<?xml version="1.0" encoding="UTF-8"?>
<!--
Description : Convertit un fichier refNum en Mets.
Version : 20160530
Auteur : Daniel Berthereau pour l'École des Mines de Paris [http://bib.mines-paristech.fr]

Cette feuille dépend de refNum2Mets.xsl.
Elle permet de normaliser certaines données du refNum.

@see http://bibnum.bnf.fr/ns/refNum.xsd
@see https://github.com/Daniel-KM/refNum2Mets
@copyright Daniel Berthereau, 2015-2016
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

    <!-- Fichier de configuration. -->
    <xsl:param name="configuration">refNum2Mets_config.xml</xsl:param>

    <!-- Constantes. -->

    <!-- Liste des paramètres du fichier de configuration. -->
    <xsl:variable name="parametres"
        select="document($configuration)/XMLlist"/>
    <!-- Liste des codes utilisés dans refNum. -->
    <xsl:variable name="codes"
        select="document($parametres/codes)/XMLlist"/>
    <!-- Liste des paramètres du profil choisi. -->
    <xsl:variable name="profil"
        select="document(r2m:cheminFichier($parametres/format/profil))/profil" />
    <!-- Paramètres pour la construction des adresses. -->
    <xsl:variable name="adresse"
        select="$parametres/adresse[@nom = ../formats/adresse_fichier[@utiliser = 'true'][1]/@nom]" />

    <!-- ==============================================================
    Fonctions d'extraction de données refNum
    =============================================================== -->

    <!-- Retourne le préfixe utilisé pour l'identifiant d'un fichier. -->
    <xsl:function name="r2m:fileIdPart">
        <xsl:param name="objetAssocie" />

        <xsl:choose>
            <xsl:when test="$objetAssocie = '' or $objetAssocie = 'master'">
                <xsl:text>master</xsl:text>
            </xsl:when>
            <xsl:when test="$codes/objetAssocie/entry[@code = $objetAssocie]/@use">
                <xsl:value-of select="$codes/objetAssocie/entry[@code = $objetAssocie]/@use" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="lower-case(translate(' ', '', normalize-space($objetAssocie)))" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- Retourne le mime type d'un fichier à partir du type de fichier texte / image / audio
    et de l'éventuel type d'objet associé. -->
    <xsl:function name="r2m:mimetypeFichier">
        <xsl:param name="typeFichier" />
        <xsl:param name="objetAssocie" />

        <xsl:choose>
            <xsl:when test="$objetAssocie = '' or $objetAssocie = 'master'">
                <xsl:value-of select="$codes/typeFichier/entry[@code = $typeFichier]/@mimetype" />
            </xsl:when>
            <xsl:when test="$codes/objetAssocie/entry[@code = $objetAssocie]/@mimetype">
                <xsl:value-of select="$codes/objetAssocie/entry[@code = $objetAssocie]/@mimetype" />
            </xsl:when>
            <xsl:when test="$codes/objetAssocie/entry[@code = $objetAssocie]/@extensionType = 'typeFichier'">
                <xsl:value-of select="$codes/typeFichier/entry[@code = $typeFichier]/@mimetype" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:text></xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- Retourne le byte order d'un fichier à partir du type de fichier texte / image / audio
    et de l'éventuel type d'objet associé. -->
    <xsl:function name="r2m:byteOrderFichier">
        <xsl:param name="typeFichier" />
        <xsl:param name="objetAssocie" />

        <xsl:choose>
            <xsl:when test="$objetAssocie = '' or $objetAssocie = 'master'">
                <xsl:value-of select="$codes/typeFichier/entry[@code = $typeFichier]/@byteOrder" />
            </xsl:when>
            <xsl:when test="$codes/objetAssocie/entry[@code = $objetAssocie]/@byteOrder">
                <xsl:value-of select="$codes/objetAssocie/entry[@code = $objetAssocie]/@byteOrder" />
            </xsl:when>
            <xsl:when test="$codes/objetAssocie/entry[@code = $objetAssocie]/@extensionType = 'typeFichier'">
                <xsl:value-of select="$codes/typeFichier/entry[@code = $typeFichier]/@byteOrder" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:text></xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- Détermine l'adresse d'un fichier (texte, image, audio) listé ou de l'objet associé. -->
    <xsl:function name="r2m:adresseFichier">
        <xsl:param name="fichier" />
        <xsl:param name="objetAssocie" />

        <xsl:variable name="typeFichier" select="upper-case($fichier/@typeFichier)" />

        <xsl:variable name="sousDossier">
            <xsl:choose>
                <xsl:when test="$objetAssocie = '' or $objetAssocie = 'master'">
                    <xsl:text>master</xsl:text>
                </xsl:when>
                <xsl:when test="$codes/objetAssocie/entry[@code = $objetAssocie]/@sousDossier">
                    <xsl:value-of select="$codes/objetAssocie/entry[@code = $objetAssocie]/@sousDossier" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text></xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="nomFichier">
            <xsl:choose>
                <xsl:when test="$objetAssocie = '' or $objetAssocie = 'master' or $adresse/nomFichierAssocie = ''">
                    <xsl:value-of select="concat($fichier/@nomTexte, $fichier/@nomImage, $fichier/@nomAudio)" />
                </xsl:when>
                <xsl:when test="$adresse/nomFichierAssocie = 'première lettre'
                    and $codes/objetAssocie/entry[@code = $objetAssocie]/@extension">
                    <xsl:value-of select="upper-case(substring($codes/objetAssocie/entry
                        [@code = $objetAssocie]/@extension, 1, 1))" />
                    <xsl:value-of select="substring(concat($fichier/@nomTexte, $fichier/@nomImage, $fichier/@nomAudio), 2)" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat($fichier/@nomTexte, $fichier/@nomImage, $fichier/@nomAudio)" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="extension">
            <xsl:choose>
                <xsl:when test="$objetAssocie = '' or $objetAssocie = 'master'">
                    <xsl:value-of select="$fichier/@typeFichier" />
                </xsl:when>
                <xsl:when test="$codes/objetAssocie/entry[@code = $objetAssocie]/@extension">
                    <xsl:value-of select="$codes/objetAssocie/entry[@code = $objetAssocie]/@extension" />
                </xsl:when>
                <xsl:when test="$codes/objetAssocie/entry[@code = $objetAssocie]/@extensionType = 'typeFichier'">
                    <xsl:value-of select="$codes/typeFichier/entry[@code = $typeFichier]/@extension" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text></xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="href">
            <xsl:value-of select="$adresse/baseUri" />
            <xsl:if test="$adresse/sousDossierDocumentPremiereLettreExtension = 'true'">
                <xsl:choose>
                    <xsl:when test="$objetAssocie = '' or $objetAssocie = 'master'">
                        <xsl:value-of select="upper-case(substring($fichier/@typeFichier, 1, 1))" />
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="upper-case(substring($codes/objetAssocie/entry
                            [@code = $objetAssocie]/@extension, 1, 1))" />
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:if>
            <xsl:if test="$adresse/sousDossierDocument = 'true'">
                <xsl:value-of select="$fichier/ancestor::refNum:document/@identifiant" />
                <xsl:text>/</xsl:text>
            </xsl:if>
            <xsl:if test="$sousDossier != '' and $adresse/sousDossierType = 'true'">
                <xsl:value-of select="$sousDossier" />
                <xsl:text>/</xsl:text>
            </xsl:if>
            <xsl:choose>
                <xsl:when test="$adresse/minusculeNomFichier = 'true'">
                    <xsl:value-of select="lower-case($nomFichier)" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$nomFichier" />
                </xsl:otherwise>
            </xsl:choose>
            <xsl:text>.</xsl:text>
            <xsl:choose>
                <xsl:when test="$adresse/minusculeExtension = 'true'">
                    <xsl:value-of select="lower-case($extension)" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$extension" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:value-of select="$href" />
    </xsl:function>

    <!-- Adresse des fichiers spéciaux (non présents dans le refnum, comme le pdf). -->
    <!-- TODO Factoriser avec r2m:adresseFichier(). -->
    <xsl:function name="r2m:adresseFichierSupplementaire">
        <!--  En fait, ici, "fichier" est la base du nom et "objetAssocie" l'extension. -->
        <xsl:param name="fichier" />
        <xsl:param name="objetAssocie" />

        <xsl:variable name="typeFichier" select="upper-case($objetAssocie)" />

        <xsl:variable name="sousDossier">
            <xsl:choose>
                <xsl:when test="$codes/objetAssocie/entry[@code = $objetAssocie]/@sousDossier">
                    <xsl:value-of select="$codes/objetAssocie/entry[@code = $objetAssocie]/@sousDossier" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text></xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="nomFichier">
            <xsl:value-of select="$fichier" />
        </xsl:variable>

        <xsl:variable name="extension">
            <xsl:choose>
                <xsl:when test="$codes/objetAssocie/entry[@code = $objetAssocie]/@extension">
                    <xsl:value-of select="$codes/objetAssocie/entry[@code = $objetAssocie]/@extension" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text></xsl:text>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="href">
            <xsl:value-of select="$adresse/baseUri" />
            <xsl:if test="$adresse/sousDossierDocumentPremiereLettreExtension = 'true'">
                <xsl:value-of select="upper-case(substring($codes/objetAssocie/entry
                    [@code = $objetAssocie]/@extension, 1, 1))" />
            </xsl:if>
            <xsl:if test="$adresse/sousDossierDocument = 'true'">
                <xsl:value-of select="$fichier" />
                <xsl:text>/</xsl:text>
            </xsl:if>
            <xsl:if test="$sousDossier != ''
                    and $adresse/sousDossierType = 'true'
                    and $profil/section/FileSection/ajout[@format = $objetAssocie]/@sousDossier = 'true'">
                <xsl:value-of select="$sousDossier" />
                <xsl:text>/</xsl:text>
            </xsl:if>
            <xsl:choose>
                <xsl:when test="$adresse/minusculeNomFichier = 'true'">
                    <xsl:value-of select="lower-case($nomFichier)" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$nomFichier" />
                </xsl:otherwise>
            </xsl:choose>
            <xsl:text>.</xsl:text>
            <xsl:choose>
                <xsl:when test="$adresse/minusculeExtension = 'true'">
                    <xsl:value-of select="lower-case($extension)" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$extension" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:value-of select="$href" />
    </xsl:function>

    <!-- Détermine la résolution ou la dimension d'une image à partir de l'élément
    combiné correspondant du refNum. -->
    <xsl:function name="r2m:extractionXY">
        <xsl:param name="valeur" />
        <xsl:param name="axe" />

        <xsl:choose>
            <xsl:when test="$valeur = ''">
                <xsl:value-of select="0" />
            </xsl:when>
            <xsl:when test="contains($valeur, ',')">
                <xsl:choose>
                    <xsl:when test="$axe = 'X'">
                        <xsl:value-of select="number(normalize-space(substring-before($valeur, ',')))" />
                    </xsl:when>
                    <xsl:when test="$axe = 'Y'">
                        <xsl:value-of select="number(normalize-space(substring-after($valeur, ',')))" />
                    </xsl:when>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="contains($valeur, 'x')">
                <xsl:choose>
                    <xsl:when test="$axe = 'X'">
                        <xsl:value-of select="number(normalize-space(substring-before($valeur, 'x')))" />
                    </xsl:when>
                    <xsl:when test="$axe = 'Y'">
                        <xsl:value-of select="number(normalize-space(substring-after($valeur, 'x')))" />
                    </xsl:when>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="number($valeur)" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- Détermine les dimensions originales. -->
    <xsl:function name="r2m:dimensionSelonUnite">
        <xsl:param name="dimension" />
        <xsl:param name="resolution" />

        <xsl:if test="$dimension > 0
            and $resolution > 0
            and ($parametres/section/AdministrativeMetadataSection/techMD/uniteResolution = 'pouce'
                or $parametres/section/AdministrativeMetadataSection/techMD/uniteResolution = 'cm')
            and ($parametres/section/AdministrativeMetadataSection/techMD/uniteSource = 'pouce'
                or $parametres/section/AdministrativeMetadataSection/techMD/uniteSource = 'cm')">
            <xsl:variable name="valeur">
                <xsl:choose>
                    <xsl:when test="$parametres/section/AdministrativeMetadataSection/techMD/uniteResolution =
                        $parametres/section/AdministrativeMetadataSection/techMD/uniteSource">
                        <xsl:value-of select="$dimension div $resolution" />
                    </xsl:when>
                    <xsl:when test="$parametres/section/AdministrativeMetadataSection/techMD/uniteResolution = 'pouce'
                        and $parametres/section/AdministrativeMetadataSection/techMD/uniteSource = 'cm'">
                        <xsl:value-of select="$dimension div $resolution * 2.54" />
                    </xsl:when>
                    <xsl:when test="$parametres/section/AdministrativeMetadataSection/techMD/uniteResolution = 'cm'
                        and $parametres/section/AdministrativeMetadataSection/techMD/uniteSource = 'pouce'">
                        <xsl:value-of select="$dimension div $resolution div 2.54" />
                    </xsl:when>
                </xsl:choose>
            </xsl:variable>
            <xsl:value-of select="format-number($valeur, $parametres/section/AdministrativeMetadataSection/techMD/unitePrecision)" />
        </xsl:if>
    </xsl:function>

    <!-- Retourne le numéro d'un fichier dans l'ordre d'apparition.
    Nécessaire car position() n'est utilisable que dans certains cas.
    -->
    <xsl:function name="r2m:numeroFichier">
        <!-- Le paramètre est le fichier texte / image / audio. -->
        <xsl:param name="fichier" />

        <xsl:value-of select="
            count($fichier/../preceding-sibling::refNum:vueObjet/refNum:*[name() = 'texte' or name() = 'image' or name() = 'audio'])
            + count($fichier/preceding-sibling::refNum:*[name() = 'texte' or name() = 'image' or name() = 'audio'])
            + 1" />
    </xsl:function>

    <!-- Retourne le nom d'une page à partir d'un objet ou d'un fichier. -->
    <xsl:function name="r2m:nomImage">
        <xsl:param name="element" />
        <xsl:param name="format" />

        <xsl:choose>
            <xsl:when test="local-name($element) = 'vueObjet'">
                <xsl:value-of select="r2m:nomPage($element, $format)" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="r2m:nomPage($element/parent::refNum:vueObjet, $format)" />
                <!-- TODO Ajout du numéro ou nom de fichier si plusieurs fichiers pour l'objet. -->
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- Retourne le nom d'une page à partir d'un objet ou d'un fichier. -->
    <xsl:function name="r2m:nomPage" as="xs:string?">
        <xsl:param name="objet" />
        <xsl:param name="format" />

        <xsl:variable name="nomPage">
            <xsl:choose>
                <xsl:when test="$objet/@numeroPage and $objet/@numeroPage != ''
                        and $objet/@numeroPage != 'NP' and $objet/@numeroPage != '0'">
                    <xsl:choose>
                        <xsl:when test="$format/titreFichier = 'numéro'">
                            <xsl:value-of select="r2m:extraitNumeroPage($objet)" />
                        </xsl:when>
                        <xsl:when test="$format/titreFichier = 'nom'">
                            <xsl:value-of select="r2m:definitNomPage($objet)" />
                        </xsl:when>
                    </xsl:choose>
                </xsl:when>

                <!-- Non paginée. -->
                <xsl:otherwise>
                    <xsl:value-of select="r2m:nomPageNonPaginee($objet, $format)" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <!-- Pour le label ou la description, il est possible d'ajouter le type
        refnum de page, s'il est différent. -->
        <xsl:variable name="ajoutTypePage">
            <xsl:if test="$format/type/@ajouter = 'true'">
                <!-- Récupère le type, sauf s'il est normal et non requis. -->
                <xsl:if test="(not(empty($objet/@typePage)) and $objet/@typePage != 'N')
                            or ($objet/@typePage = 'N' and $format/type/@normal = 'true')">
                    <xsl:variable name="typePage"
                        select="$codes/typePage/entry[@code = $objet/@typePage]" />
                    <xsl:if test="$typePage != $nomPage">
                        <xsl:value-of select="$format/type/@separateur" />
                        <xsl:value-of select="$typePage" />
                    </xsl:if>
                </xsl:if>
            </xsl:if>
        </xsl:variable>

        <!-- La concaténation permet d'éviter les problèmes d'espace. -->
        <xsl:value-of select="concat($nomPage, $ajoutTypePage)" />
    </xsl:function>

    <!-- Retourne le nom d'une page non paginée à partir de l'objet. -->
    <xsl:function name="r2m:nomPageNonPaginee">
        <xsl:param name="objet" />
        <xsl:param name="format" />

        <xsl:choose>
            <xsl:when test="$format/titreFichierNP = 'vide'">
                <xsl:text></xsl:text>
            </xsl:when>
            <xsl:when test="$format/titreFichierNP = 'fixe'">
                <xsl:value-of select="$format/titreFichierNPTexte" />
            </xsl:when>
            <xsl:when test="$format/titreFichierNP = 'ordre'">
                <xsl:value-of select="normalize-space(concat(
                        $format/titreFichierNPTexte,
                        $objet/@ordre,
                        $format/titreFichierNPTexteAp
                    ))" />
            </xsl:when>
            <xsl:when test="$format/titreFichierNP = 'numéro NP'">
                <xsl:variable name="numeroPage" select="string(count(
                        $objet/preceding-sibling::refNum:vueObjet[not(@numeroPage) or @numeroPage = '' or @numeroPage = 'NP' or @numeroPage = '0']
                    ) + 1)" />
                <xsl:value-of select="normalize-space(concat(
                        $format/titreFichierNPTexte,
                        $numeroPage,
                        $format/titreFichierNPTexteAp
                    ))" />
            </xsl:when>
            <xsl:when test="$format/titreFichierNP = 'numéro déduit'">
                <xsl:value-of select="normalize-space(
                        r2m:nomPageDeduit($objet, $format)
                    )" />
            </xsl:when>
            <xsl:when test="$format/titreFichierNP = 'nom'">
                <xsl:value-of select="normalize-space(
                        r2m:nomPageDeduit($objet, $format)
                    )" />
            </xsl:when>
        </xsl:choose>
    </xsl:function>

    <!-- Détermine le numéro d'une page non paginée à partir d'un objet. -->
    <xsl:function name="r2m:nomPageDeduit">
        <xsl:param name="objet" />
        <xsl:param name="format" />

        <!-- Note sur le nommage des pages des lots : le lot peut être un
        manuscrit paginé (donc une monographie), des dessins. des feuillets
        réunis sous le nom de page, un ensemble de documents de quelques
        pages... Le nommage suit les mêmes règles, sauf pour la couverture. -->
        <xsl:variable name="précédente_numérotée"
            select="($objet/preceding-sibling::refNum:vueObjet[@typePagination != 'N'])[last()]"/>
        <xsl:variable name="suivante_numérotée"
            select="($objet/following-sibling::refNum:vueObjet[@typePagination != 'N'])[1]"/>

        <xsl:choose>
            <!-- Aucune page numérotée. -->
            <xsl:when test="not($précédente_numérotée) and not($suivante_numérotée)">
                <xsl:value-of select="r2m:nomPageNonPagineeFormat(
                    $objet/@ordre,
                    false(), $format, 'Image ', '')" />
            </xsl:when>

            <!-- Pages initiales. -->
            <xsl:when test="not($précédente_numérotée)">
                <!-- Exemple : si la première page numérotée est 3, on
                peut déduire que les deux précédentes sont 1 et 2. -->
                <!-- Il ne peut pas y avoir de feuillet ici. -->
                <xsl:choose>
                    <!-- Numérotation incorrecte de la première page paginée suivante. -->
                    <xsl:when test="($suivante_numérotée/@typePagination = 'A'
                                or $suivante_numérotée/@typePagination = 'R')
                            and not(number($suivante_numérotée/@numeroPage))">
                        <xsl:value-of select="r2m:nomPageNonPagineeFormat(
                            $objet/@ordre,
                            false(), $format, 'Image ', '')" />
                    </xsl:when>

                    <!-- Pagination en chiffres arabes. -->
                    <xsl:when test="($suivante_numérotée/@typePagination = 'A')
                        and (number($suivante_numérotée/@numeroPage) > 1)
                        and (number($suivante_numérotée/@numeroPage) + $objet/@ordre > $suivante_numérotée/@ordre)
                        ">
                        <xsl:value-of select="r2m:nomPageNonPagineeFormat(
                            number($suivante_numérotée/@numeroPage) - $suivante_numérotée/@ordre + $objet/@ordre,
                            true(), $format, 'Page ', ' (non paginée)')" />
                    </xsl:when>

                    <!-- Pagination en chiffres romain. -->
                    <xsl:when test="($suivante_numérotée/@typePagination = 'R')
                        and (number($suivante_numérotée/@numeroPage) > 1)
                        and (number($suivante_numérotée/@numeroPage) + $objet/@ordre > $suivante_numérotée/@ordre)
                        ">
                        <xsl:value-of select="r2m:nomPageNonPagineeFormat(
                            r2m:conversionArabeVersRomain(number($suivante_numérotée/@numeroPage) - $suivante_numérotée/@ordre + $objet/@ordre),
                            true(), $format, 'Page ', ' (non paginée)')" />
                    </xsl:when>

                    <!-- Couvertures et pages de garde (sauf lot). -->
                    <xsl:otherwise>
                        <xsl:choose>
                            <!-- Lot : pas de couverture. -->
                            <xsl:when test="$objet/../../refNum:bibliographie/refNum:genre = 'LOT'">
                                <xsl:value-of select="r2m:nomPageNonPagineeFormat(
                                    $objet/@ordre,
                                    false(), $format, 'Image ', '')" />
                            </xsl:when>

                            <!-- Couvertures. -->
                            <xsl:when test="$objet/@ordre = 1">
                                <xsl:text>Couverture</xsl:text>
                            </xsl:when>
                            <xsl:when test="$objet/@ordre = 2">
                                <xsl:text>Deuxième de couverture</xsl:text>
                            </xsl:when>
                            <xsl:when test="$objet/@typePage = 'P'">
                                <xsl:text>Page de titre</xsl:text>
                            </xsl:when>

                            <!-- Pages de garde. -->
                            <xsl:otherwise>
                                <!-- Exception. -->
                                <xsl:choose>
                                    <xsl:when test="$format/titreFichierNP = 'numéro déduit'">
                                        <xsl:value-of select="r2m:nomPageNonPagineeFormat(
                                            $objet/@ordre,
                                            false(), $format, 'Page de garde ', '')" />
                                    </xsl:when>

                                    <xsl:otherwise>
                                        <xsl:value-of select="r2m:nomPageNonPagineeFormat(
                                            $objet/@ordre - 2,
                                            true(), $format, 'Page de garde ', '')" />
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>

            <!-- Foliotation. -->
            <xsl:when test="($précédente_numérotée/@typePagination = 'F')
                and ($précédente_numérotée/@ordre + 1 = $objet/@ordre)
                and number($précédente_numérotée/@numeroPage)
                ">
                <xsl:value-of select="r2m:nomPageNonPagineeFormat(
                    number($précédente_numérotée/@numeroPage),
                    'folio', $format, 'Folio ', ' (verso)')" />
            </xsl:when>

            <!-- Pages finales et couverture (sauf lot). -->
            <xsl:when test="not($suivante_numérotée)">
                <xsl:choose>
                    <!-- Lot : pas de couverture. -->
                    <xsl:when test="$objet/../../refNum:bibliographie/refNum:genre = 'LOT'">
                        <xsl:value-of select="r2m:nomPageNonPagineeFormat(
                            $objet/@ordre,
                            false(), $format, 'Image ', '')" />
                    </xsl:when>
                    <!-- Couvertures. -->
                    <xsl:when test="$objet/@ordre = (($objet/following-sibling::refNum:vueObjet)[last()]/@ordre - 1)">
                        <xsl:text>Troisième de couverture</xsl:text>
                    </xsl:when>
                    <xsl:when test="not($objet/following-sibling::*)">
                        <xsl:text>Quatrième de couverture</xsl:text>
                    </xsl:when>
                    <!-- Pages finales. -->
                    <xsl:otherwise>
                        <xsl:value-of select="r2m:nomPageNonPagineeFormat(
                            $objet/@ordre - $précédente_numérotée/@ordre,
                            true(), $format, 'Page de fin ', '')" />
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>

            <!-- La page se situe entre deux numéros et son numéro est
            déterminable avec une bonne probabilité. -->

            <!--  Un test de validité sur les numéros de page évite une erreur
            avec les fichiers mal formatés. -->
            <xsl:when test="number($précédente_numérotée/@numeroPage)
                    and number($suivante_numérotée/@numeroPage)">
                <xsl:choose>
                    <!-- Pagination entre deux chiffres arabes, avec test de
                    cohérence par comparaison de la précédente et de la suivante. -->
                    <xsl:when test="($précédente_numérotée/@typePagination = 'A')
                            and ($suivante_numérotée/@typePagination = 'A')
                            and ($suivante_numérotée/@numeroPage - $suivante_numérotée/@ordre
                                = $précédente_numérotée/@numeroPage - $précédente_numérotée/@ordre
                            )
                            ">
                            <xsl:value-of select="r2m:nomPageNonPagineeFormat(
                                $suivante_numérotée/@numeroPage - $suivante_numérotée/@ordre + $objet/@ordre,
                                true(), $format, 'Page ', ' (non paginée)')" />
                    </xsl:when>

                    <!-- Pagination entre deux chiffres arabes, avec test de
                    cohérence par comparaison de la précédente et de la suivante
                    et écart double (insertion de feuillets). Exemple :
                    5 > 11 / 6 > 12 / 7 > x > 13R / 8 > x > 13V / 9 > x > 14R / 10 > x > 14V / 11 > 15.
                    On considère que les feuilles sont numérotées dans l'ordre
                    normal : ordre impair = recto.
                    -->
                    <xsl:when test="($précédente_numérotée/@typePagination = 'A')
                            and ($suivante_numérotée/@typePagination = 'A')
                            and (
                                ($suivante_numérotée/@numeroPage - $précédente_numérotée/@numeroPage - 1) * 2
                                    = $suivante_numérotée/@ordre - $précédente_numérotée/@ordre - 1
                            )
                            ">
                            <xsl:value-of select="r2m:nomPageNonPagineeFormat(
                                    $suivante_numérotée/@numeroPage - ceiling(($suivante_numérotée/@ordre - $objet/@ordre) div 2),
                                    'folio', $format, 'Folio ', if ($objet/@ordre mod 2 = 1) then ' (recto)' else ' (verso')" />
                    </xsl:when>

                    <!-- Pagination entre deux chiffres romains, avec test de
                    cohérence par comparaison de la précédente et de la suivante.. -->
                    <xsl:when test="($précédente_numérotée/@typePagination = 'R')
                            and ($suivante_numérotée/@typePagination = 'R')
                            and ($suivante_numérotée/@numeroPage - $suivante_numérotée/@ordre
                                = $précédente_numérotée/@numeroPage - $précédente_numérotée/@ordre
                            )
                            ">
                            <xsl:value-of select="r2m:nomPageNonPagineeFormat(
                                r2m:conversionArabeVersRomain($suivante_numérotée/@numeroPage - $suivante_numérotée/@ordre + $objet/@ordre),
                                true(), $format, 'Page ', ' (non paginée)')" />
                    </xsl:when>

                    <!-- Pagination entre deux chiffres romains, avec test de
                    cohérence par comparaison de la précédente et de la suivante
                    et écart double (insertion de feuillets). Exemple :
                    5 > 11 / 6 > 12 / 7 > x > 13R / 8 > x > 13V / 9 > x > 14R / 10 > x > 14V / 11 > 15.
                    On considère que les feuilles sont numérotées dans l'ordre
                    normal : ordre impair = recto.
                    -->
                    <xsl:when test="($précédente_numérotée/@typePagination = 'R')
                            and ($suivante_numérotée/@typePagination = 'R')
                            and (
                                ($suivante_numérotée/@numeroPage - $précédente_numérotée/@numeroPage - 1) * 2
                                = $suivante_numérotée/@ordre - $précédente_numérotée/@ordre - 1
                            )
                            ">
                            <xsl:value-of select="r2m:nomPageNonPagineeFormat(
                                    r2m:conversionArabeVersRomain($suivante_numérotée/@numeroPage - ceiling(($suivante_numérotée/@ordre - $objet/@ordre) div 2)),
                                    'folio', $format, 'Folio ', if ($objet/@ordre mod 2 = 1) then ' (recto)' else ' (verso')" />
                    </xsl:when>

                    <!-- Pagination entre deux folios, avec test de cohérence
                    par comparaison de la précédente et de la suivante. -->
                    <xsl:when test="($précédente_numérotée/@typePagination = 'F')
                            and ($suivante_numérotée/@typePagination = 'F')
                            and (
                                $suivante_numérotée/@numeroPage - $précédente_numérotée/@numeroPage
                                = ($suivante_numérotée/@ordre - $précédente_numérotée/@ordre) div 2
                            )
                            ">
                            <xsl:value-of select="r2m:nomPageNonPagineeFormat(
                                    $suivante_numérotée/@numeroPage - ceiling(($suivante_numérotée/@ordre - $objet/@ordre) div 2),
                                    'folio', $format, 'Folio ', if ($objet/@ordre mod 2 = 1) then ' (recto)' else ' (verso')" />
                    </xsl:when>

                    <!-- Impossible à déterminer, sans doute avec du hors-texte,
                    ou un document mal numéroté. -->
                    <xsl:otherwise>
                        <xsl:value-of select="r2m:nomPageNonPagineeFormat(
                            $objet/@ordre,
                            false(), $format, 'Image ', '')" />
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>

            <!-- Impossible à déterminer, sans doute avec du hors-texte,
            ou un document mal numéroté. -->
            <xsl:otherwise>
                <xsl:value-of select="r2m:nomPageNonPagineeFormat(
                    $objet/@ordre,
                    false(), $format, 'Image ', '')" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="r2m:nomPageNonPagineeFormat">
        <xsl:param name="numero" />
        <xsl:param name="trouve" />
        <xsl:param name="format" />
        <xsl:param name="texteAv" />
        <xsl:param name="texteAp" />

        <xsl:choose>
            <xsl:when test="$format/titreFichierNP = 'numéro déduit'">
                <xsl:choose>
                    <xsl:when test="$trouve = true()">
                        <xsl:value-of select="string($numero)" />
                    </xsl:when>
                    <xsl:when test="string($trouve) = 'folio'">
                        <xsl:value-of select="concat(string($numero), ' (verso)')" />
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="normalize-space(concat(
                            $format/titreFichierNPTexte,
                            string($numero),
                            $format/titreFichierNPTexteAp))" />
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="normalize-space(concat($texteAv, string($numero), $texteAp))" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="r2m:conversionArabeVersRomain">
        <xsl:param name="nombre" />

        <xsl:number value="$nombre" format="I"/>
    </xsl:function>

    <!-- Extrait le numéro d'une page, notamment s'il est en romain ou mal formaté. -->
    <xsl:function name="r2m:extraitNumeroPage" as="xs:string?">
        <xsl:param name="objet" />

        <xsl:choose>
            <!-- Prend en compte le cas où le numéroPage n'est pas convertissable :
            "Planche 3.1". Dans ce cas prend du premier chiffre au dernier chiffre ("3.1"). -->
            <xsl:when test="$objet/@typePagination = 'A' and not(number($objet/@numeroPage))">
                <xsl:variable name="chiffres" select="replace($objet/@numeroPage, '[^0-9]', '')" />
                <xsl:choose>
                    <xsl:when test="$chiffres = ''">
                        <xsl:value-of select="normalize-space($objet/@numeroPage)" />
                    </xsl:when>
                    <xsl:when test="string-length($chiffres) = 1">
                        <xsl:value-of select="$chiffres" />
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:variable name="premier_chiffre" select="substring($chiffres, 1, 1)" />
                        <xsl:variable name="dernier_chiffre" select="substring($chiffres, string-length($chiffres), 1)" />
                        <xsl:variable name="position_premier_chiffre" select="1 + string-length(substring-before($objet/@numeroPage, $premier_chiffre))" />
                        <xsl:variable name="position_dernier_chiffre" select="r2m:lastCharIndex($objet/@numeroPage, $dernier_chiffre)" />
                        <xsl:value-of select="substring($objet/@numeroPage, $position_premier_chiffre, $position_dernier_chiffre - $position_premier_chiffre + 1)" />
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>

            <!-- Prend en compte le cas où le numéroPage n'est pas convertissable :
            "Planche IX". Dans ce cas prend le premier mot qui soit un nombre romain ("IX"). -->
            <xsl:when test="$objet/@typePagination = 'R' and not(number($objet/@numeroPage))">
                <xsl:variable name="nombre" select="r2m:extraitRomain($objet/@numeroPage)" />
                <xsl:choose>
                    <xsl:when test="$nombre = '0' or $nombre = ''">
                        <xsl:value-of select="normalize-space($objet/@numeroPage)" />
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$nombre" />
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>

            <!-- Exception : convertir en romain le numéro de page romain (qui est en arabe). -->
            <xsl:when test="$objet/@typePagination = 'R'">
                <xsl:value-of select="normalize-space(r2m:conversionArabeVersRomain($objet/@numeroPage))" />
            </xsl:when>

            <!-- Cas normal : le numéro page est correctement écrit. -->
            <xsl:otherwise>
                <xsl:value-of select="normalize-space($objet/@numeroPage)" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- Détermine le nom d'une page, notamment s'il est en romain ou mal formaté. -->
    <xsl:function name="r2m:definitNomPage" as="xs:string?">
        <xsl:param name="objet" />

        <xsl:choose>
            <!-- Pagination en chiffres arabes. -->
            <xsl:when test="$objet/@typePagination = 'A'">
                <xsl:choose>
                    <!-- Pagination en chiffres arabes, mais mal formaté, donc on garde. -->
                    <xsl:when test="not(number($objet/@numeroPage))">
                        <xsl:value-of select="normalize-space($objet/@numeroPage)" />
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="normalize-space(concat('Page ', $objet/@numeroPage))" />
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>

            <!-- Pagination en chiffres romains. -->
            <xsl:when test="$objet/@typePagination = 'R'">
                <xsl:choose>
                    <!-- Pagination en chiffres romains, mais mal formaté. -->
                    <xsl:when test="not(number($objet/@numeroPage))">
                        <xsl:choose>
                            <!-- C'est mal formaté et il y a un nom en plus : on garde. -->
                            <xsl:when test="contains($objet/@numeroPage, ' ')">
                                <xsl:value-of select="normalize-space($objet/@numeroPage)" />
                            </xsl:when>
                            <!-- Normalement, c'est déjà en romain, donc on garde. -->
                            <xsl:otherwise>
                                <xsl:value-of select="normalize-space(concat('Page ', $objet/@numeroPage))" />
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="normalize-space(concat('Page ', r2m:conversionArabeVersRomain($objet/@numeroPage)))" />
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>

            <!-- Foliotation. -->
            <xsl:when test="$objet/@typePagination = 'F'">
                <xsl:value-of select="normalize-space(concat('Folio ', $objet/@numeroPage, ' (recto)'))" />
            </xsl:when>

            <!-- Pagination autre. -->
            <xsl:when test="$objet/@typePagination = 'X'">
                <xsl:value-of select="normalize-space(concat('Page ', $objet/@numeroPage))" />
            </xsl:when>

            <!-- Peut arriver ici dans le cas de lots ou d'une erreur. -->
            <xsl:otherwise>
                <xsl:value-of select="normalize-space(concat('Image ', $objet/@numeroPage))" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- Détermine la date maximale pour un fichier (eventDateTime).
    Lorsqu'il y a plusieurs dates, prend la dernière.
    TODO Fonctionne seulement si toutes les dates respectent un minimum un format.
    -->
    <xsl:function name="r2m:trouveDateValidation" as="xs:string">
        <xsl:param name="fichier" />
        <xsl:param name="objetAssocie" />

        <xsl:choose>
            <xsl:when test="name($fichier) = 'texte' or name($fichier) = 'image' or name($fichier) = 'audio'">
                <xsl:variable name="dateCommentaireFichier"
                    select="$fichier/refNum:commentaire[position() = last()]/@date" />
                <xsl:variable name="dateCommentaireObjet"
                    select="$fichier/parent::refNum:vueObjet/refNum:commentaire[position() = last()]/@date" />
                <xsl:variable name="dateCommentaireStructure"
                    select="$fichier/ancestor::refNum:structure/refNum:commentaire[position() = last()]/@date" />
                <xsl:variable name="dateObjetAssocie"
                    select="$fichier/ancestor::refNum:document/refNum:production/refNum:objetAssocie[text() = $objetAssocie][position() = last()]/@date" />
                <!-- TODO Ajouter la date correspondant à l'objet associé dans l'historique des opérations, même si c'est redondant. -->

                <xsl:variable name="comparaison_1" select="r2m:maxDate($dateCommentaireFichier, $dateCommentaireObjet)" />
                <xsl:variable name="comparaison_2" select="r2m:maxDate($comparaison_1, $dateCommentaireStructure)" />
                <xsl:variable name="comparaison_3" select="r2m:maxDate($comparaison_2, $dateObjetAssocie)" />

                <xsl:value-of select="$comparaison_3" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:text></xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="r2m:maxDate">
        <xsl:param name="date1" />
        <xsl:param name="date2" />

        <xsl:choose>
            <xsl:when test="string($date1) = '' and string($date2) = ''">
                <xsl:text></xsl:text>
            </xsl:when>
            <xsl:when test="string($date1) = ''">
                <xsl:value-of select="$date2" />
            </xsl:when>
            <xsl:when test="string($date2) = ''">
                <xsl:value-of select="$date1" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="
                    if ($date1 &gt; $date2) then $date1 else $date2
                    " />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- Retourne l'orientation (sens de lecture) d'une image. -->
    <xsl:function name="r2m:valeurOrientation">
        <xsl:param name="objet" />

        <xsl:variable name="orientation"
            select="$codes/orientation/entry[@code = $objet/@orientation]/text()" />

        <xsl:choose>
            <!-- Pas de code. -->
            <xsl:when test="empty($objet/@orientation) or $objet/@orientation = ''">
                <xsl:text></xsl:text>
            </xsl:when>
            <!-- C'est un code. -->
            <xsl:when test="$orientation != ''">
                <xsl:value-of select="$orientation" />
            </xsl:when>
            <!-- C'est un nombre, ou non standard. -->
            <xsl:otherwise>
                <xsl:value-of select="$objet/@orientation" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- Retourne la position d'une image. -->
    <xsl:function name="r2m:valeurPosition">
        <xsl:param name="objet" />

        <xsl:variable name="position"
            select="$codes/positionPage/entry[@code = $objet/@positionPage]/text()" />

        <xsl:choose>
            <!-- Pas de code. -->
            <xsl:when test="empty($objet/@positionPage) or $objet/@positionPage = ''">
                <xsl:text></xsl:text>
            </xsl:when>
            <!-- C'est un code. -->
            <xsl:when test="$position != ''">
                <xsl:value-of select="$position" />
            </xsl:when>
            <!-- C'est quelque chose de non standard. -->
            <xsl:otherwise>
                <xsl:value-of select="$objet/@positionPage" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>


    <!-- Vérifie la conformité de la position d'une page à son ordre. -->
    <!-- Fonctionne seulement pour Gauche / Droite. -->
    <xsl:function name="r2m:estPositionNormale" as="xs:boolean">
        <xsl:param name="position" />
        <xsl:param name="ordre" />

        <xsl:value-of select="
                (($position = 'Left' or $position = 'L') and number($ordre) mod 2 = 0)
                or (($position = 'Right' or $position = 'R') and number($ordre) mod 2 = 1)
            " />
    </xsl:function>

    <!-- Trouve le nombre romain dans une chaine et le renvoi tel quel. -->
    <xsl:function name="r2m:extraitRomain" as="xs:string?">
        <xsl:param name="str" />

        <!-- Pour chaque mot, vérifie si c'est un nombre romain. -->
        <xsl:variable name="romains">
            <xsl:for-each select="tokenize($str, ' ')">
                <xsl:variable name="romain" select="r2m:romanToInteger(.)" />
                <xsl:choose>
                    <xsl:when test="$romain > 0">
                        <xsl:value-of select="." />
                        <xsl:value-of select="' '" />
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="''" />
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </xsl:variable>

        <!-- Retourne le premier romain le cas échéant. -->
        <xsl:value-of select="if (string-length($romains) > 0)
                then substring-before($romains, ' ')
                else ''" />
    </xsl:function>

    <!-- Conversion d'un nombre romain en entier.
    Corrigé à partir de David Carlisle, http://www.stylusstudio.com/xsllist/handler.asp?/xsllist/200412/post31060.html
    -->
    <xsl:function name="r2m:romanToInteger" as="xs:integer">
        <xsl:param name="r" as="xs:string"/>

        <xsl:choose>
            <xsl:when test="ends-with($r, 'IIX')">
                <xsl:sequence select="8 + r2m:romanToInteger(substring($r, 1, string-length($r) - 3))"/>
            </xsl:when>
            <xsl:when test="ends-with($r, 'IIL')">
                <xsl:sequence select="48 + r2m:romanToInteger(substring($r, 1, string-length($r) - 3))"/>
            </xsl:when>
            <xsl:when test="ends-with($r, 'IIC')">
                <xsl:sequence select="98 + r2m:romanToInteger(substring($r, 1, string-length($r) - 3))"/>
            </xsl:when>
            <xsl:when test="ends-with($r, 'IID')">
                <xsl:sequence select="498 + r2m:romanToInteger(substring($r, 1, string-length($r) - 3))"/>
            </xsl:when>
            <xsl:when test="ends-with($r, 'IIM')">
                <xsl:sequence select="998 + r2m:romanToInteger(substring($r, 1, string-length($r) - 3))"/>
            </xsl:when>

            <xsl:when test="ends-with($r, 'IV')">
                <xsl:sequence select="4 + r2m:romanToInteger(substring($r, 1, string-length($r) - 2))"/>
            </xsl:when>
            <xsl:when test="ends-with($r, 'IX')">
                <xsl:sequence select="9 + r2m:romanToInteger(substring($r, 1, string-length($r) - 2))"/>
            </xsl:when>

            <xsl:when test="ends-with($r, 'IC')">
                <xsl:sequence select="99 + r2m:romanToInteger(substring($r, 1, string-length($r) - 2))"/>
            </xsl:when>
            <xsl:when test="ends-with($r, 'VC')">
                <xsl:sequence select="95 + r2m:romanToInteger(substring($r, 1, string-length($r) - 2))"/>
            </xsl:when>
            <xsl:when test="ends-with($r, 'XC')">
                <xsl:sequence select="90 + r2m:romanToInteger(substring($r, 1, string-length($r) - 2))"/>
            </xsl:when>

            <xsl:when test="ends-with($r, 'ID')">
                <xsl:sequence select="499 + r2m:romanToInteger(substring($r, 1, string-length($r) - 2))"/>
            </xsl:when>
            <xsl:when test="ends-with($r, 'VD')">
                <xsl:sequence select="495 + r2m:romanToInteger(substring($r, 1, string-length($r) - 2))"/>
            </xsl:when>
            <xsl:when test="ends-with($r, 'XD')">
                <xsl:sequence select="490 + r2m:romanToInteger(substring($r, 1, string-length($r) - 2))"/>
            </xsl:when>
            <xsl:when test="ends-with($r, 'LD')">
                <xsl:sequence select="450 + r2m:romanToInteger(substring($r, 1, string-length($r) - 2))"/>
            </xsl:when>
            <xsl:when test="ends-with($r, 'CD')">
                <xsl:sequence select="400 + r2m:romanToInteger(substring($r, 1, string-length($r) - 2))"/>
            </xsl:when>

            <xsl:when test="ends-with($r, 'IM')">
                <xsl:sequence select="999 + r2m:romanToInteger(substring($r, 1, string-length($r) - 2))"/>
            </xsl:when>
            <xsl:when test="ends-with($r, 'VM')">
                <xsl:sequence select="995 + r2m:romanToInteger(substring($r, 1, string-length($r) - 2))"/>
            </xsl:when>
            <xsl:when test="ends-with($r, 'XM')">
                <xsl:sequence select="990 + r2m:romanToInteger(substring($r, 1, string-length($r) - 2))"/>
            </xsl:when>
            <xsl:when test="ends-with($r, 'LM')">
                <xsl:sequence select="950 + r2m:romanToInteger(substring($r, 1, string-length($r) - 2))"/>
            </xsl:when>
            <xsl:when test="ends-with($r, 'CM')">
                <xsl:sequence select="900 + r2m:romanToInteger(substring($r, 1, string-length($r) - 2))"/>
            </xsl:when>

            <xsl:when test="ends-with($r, 'I')">
                <xsl:sequence select="1 + r2m:romanToInteger(substring($r, 1, string-length($r) - 1))"/>
            </xsl:when>
            <xsl:when test="ends-with($r, 'V')">
                <xsl:sequence select="5 + r2m:romanToInteger(substring($r, 1, string-length($r) - 1))"/>
            </xsl:when>
            <xsl:when test="ends-with($r, 'X')">
                <xsl:sequence select="10 + r2m:romanToInteger(substring($r, 1, string-length($r) - 1))"/>
            </xsl:when>
            <xsl:when test="ends-with($r, 'L')">
                <xsl:sequence select="50 + r2m:romanToInteger(substring($r, 1, string-length($r) - 1))"/>
            </xsl:when>
            <xsl:when test="ends-with($r, 'C')">
                <xsl:sequence select="100 + r2m:romanToInteger(substring($r, 1, string-length($r) - 1))"/>
            </xsl:when>
            <xsl:when test="ends-with($r, 'D')">
                <xsl:sequence select="500 + r2m:romanToInteger(substring($r, 1, string-length($r) - 1))"/>
            </xsl:when>
            <xsl:when test="ends-with($r, 'M')">
                <xsl:sequence select="1000 + r2m:romanToInteger(substring($r, 1, string-length($r) - 1))"/>
            </xsl:when>

            <xsl:otherwise>
                <xsl:sequence select="0"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="r2m:lastCharIndex">
        <xsl:param name="str" as="xs:string"/>
        <xsl:param name="char" as="xs:string"/>

        <xsl:call-template name="lastCharIndex">
            <xsl:with-param name="pText" select="$str" />
            <xsl:with-param name="pChar" select="$char" />
        </xsl:call-template>
     </xsl:function>

    <!-- From Dimitre Novatchev, https://stackoverflow.com/questions/12642166/how-to-get-the-last-index-of-a-char-in-a-string -->
    <xsl:template name="lastCharIndex">
        <xsl:param name="pText" />
        <xsl:param name="pChar" />

        <xsl:variable name="vRev">
            <xsl:call-template name="reverse">
                <xsl:with-param name="pStr" select="$pText"/>
            </xsl:call-template>
        </xsl:variable>

        <xsl:value-of select="string-length($pText) - string-length(substring-before($vRev, $pChar))"/>
    </xsl:template>

    <xsl:template name="reverse">
        <xsl:param name="pStr"/>

        <xsl:variable name="vLength" select="string-length($pStr)"/>
        <xsl:choose>
            <xsl:when test="$vLength = 1">
                <xsl:value-of select="$pStr"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="vHalfLength" select="floor($vLength div 2)"/>
                <xsl:variable name="vrevHalf1">
                    <xsl:call-template name="reverse">
                        <xsl:with-param name="pStr"
                            select="substring($pStr, 1, $vHalfLength)"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:variable name="vrevHalf2">
                    <xsl:call-template name="reverse">
                        <xsl:with-param name="pStr"
                        select="substring($pStr, $vHalfLength + 1)"/>
                    </xsl:call-template>
                </xsl:variable>

                <xsl:value-of select="concat($vrevHalf2, $vrevHalf1)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>

<?xml version="1.0" encoding="UTF-8"?>
<!--
Description : Convertit un fichier refNum en Mets.
Version : 20150921
Auteur : Daniel Berthereau pour l'École des Mines de Paris [http://bib.mines-paristech.fr]

refnum2Mets est un outil pour convertir des fichiers xml du format refNum
vers le format Mets, deux formats utilisés pour gérer des documents numérisés
et pour construire des bibliothèques numériques.

Le format refNum est un format défini par la Bibliothèque nationale de France
(BnF) pour gérer les numérisations de documents (livres, journaux, objets,
audio). Il est officiellement abandonné depuis décembre 2014 au profit du Mets
(mais officieusement encore utilisé et toujours mis à jour) .

Cet outil permet donc de mettre à jour ses fichiers de métadonnées en conservant
l'ensemble des informations du premier format et éventuellement en en ajoutant
de nouvelles.

Cette feuille a été vérifiée avec les documents numérisés de la bibliothèque
de l'École des Mines de Paris et de l'École des Ponts (monographies,
manuscrits, périodiques, lots de photos), mis en ligne sur leurs sites
respectifs Bibliothèque patrimoniale des Mines [https://patrimoine.mines-paristech.fr]
et Collections patrimoniales des Ponts [http://patrimoine.enpc.fr] via la
plateforme libre Omeka [https://omeka.org]. Elle gère aussi quelques variantes
du refNum (genre inconnu, dates multiples, etc.). À l'inverse, certaines spécificités du
refNum ne sont pas prises en compte, notamment pour les objets "texte" et
"audio" et pour les fichiers associés.

Le format est conçu sur la base du profil METS SIP de la BnF (noms des
identifiants...) et sur les différents documents disponibles sur la page
consacrée aux bibliothèques numériques [http://bibnum.bnf.fr] sur le site de la
BnF, mais il est possible de s'en écarter pour simplifier ou enrichir le
résultat.

L'ensemble des paramètres sont à indiquer dans le fichier de configuration
associé.

Remarques générales

- Les formats des identifiants respectent le format BnF, qui définit le préfixe
obligatoire :
    - Format du DMDID de la notice principale : "DMD.2" pour les périodiques,
    sinon "DMD.1"
    - Format des ADMID : "1"
    - Format du File ID des fichiers : type.ordre fichier : "master.1", "ocr.5".
- Les notices peuvent être enrichies avec un nom de page, y compris pour les
pages non paginées, dont le numéro est déduit des pages précédentes et
suivantes. L'algorithme répond à la plupart des usages courants, mais une
vérification peut s'avérer utile.
- Dans l'exemple BnF, traitement/operation/entrée|description|resultat
correspondent à des "detailsOperation", mais ce format contient aussi une
description et un résultat, ce qui entraîne, comme dans l'exemple Mets BnF, des
redites.
- Gère le namespace "detailsOperation" même s'il n'est pas déclaré séparément
(l'exemple de la BnF fusionne ces espaces).
- Dans Operation, la date était indiquée à ce niveau initialement, mais a été
supprimée ensuite, car elle se trouve dans le niveau inférieur. Elle n'est pas
reprise actuellement dans ce modèle.
- La date de résultat n'est pas conservée par la BnF et elle n'est pas
indiquable dans un champ Premis. Une option permet donc de l'ajouter en note.
- Dans l'exemple BnF, certaines données proviennent d'autres sources et
n'apparaissent donc pas dans la conversion vers le refNum. Même si elles peuvent
être reconstruite (opérations de démarrage, de contrôle, d'information, etc.),
cela ne présente pas d'intérêt et les informations ne sont pas requises par la
norme Mets.

TODO
- Vérifier avec davantage d'exemples.
- Ajouter ALTO (déjà inclus via fichiers associés).
- Vérifier la gestion de plusieurs images pour une même vueObjet.
- Ajouter des contrôles de cohérence du refNum (nombre d'objets et fichiers...).
- Récupérer les infos des images pour les données techniques.
- Récupérer les infos techniques des images via un script.
- Code de résolution des images ?
- Gestion de supports plus différents.
- Gérer typeGammeCommandee / typeGammeRealisee
- Ajouter la légende des images
- Ajouter périodique

Historique
2015/09/21 Ajout des notices de documents et des métadonnées descriptives des pages
2015/09/07 Corrections de détails et ajout d'un script pour traiter les dossiers
2015/06/22 Version pour publication
2015/03/16 Version initiale (Mines ParisTech)

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

    xmlns:spar_dc="http://bibnum.bnf.fr/ns/spar_dc"

    xmlns:alto="http://bibnum.bnf.fr/ns/alto_prod"

    xmlns="http://www.loc.gov/METS/"
    xmlns:mets="http://www.loc.gov/METS/"
    xmlns:premis="info:lc/xmlns/premis-v2"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:xlink="http://www.w3.org/1999/xlink"
    xmlns:dcterms="http://purl.org/dc/terms/"
    xmlns:niso="http://www.niso.org/Z39-87-2006.pdf"
    xmlns:textmd="info:lc/xmlns/textMD-v3"

    exclude-result-prefixes="
        xsl fn xs r2m refNum detailsOperation
        spar_dc
        alto
        mets textmd
        ">

    <!-- Import des outils. -->
    <xsl:import href="refNum2Mets_fonctions.xsl" />
    <xsl:import href="refNum2Mets_refnum.xsl" />
    <xsl:import href="refNum2Mets_numerotation.xsl" />
    <xsl:import href="refNum2Mets_bnf.xsl" />

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

    <!-- Totaux utilisés pour établir les numéros d'identifiants. -->
    <xsl:variable name="nombreOperations"
        select="count(/refNum:refNum/refNum:document/refNum:production/refNum:historique/refNum:traitement/refNum:operation)" />

    <!-- Détermination du nom des divisions. -->
    <xsl:variable name="structure_types">
        <xsl:choose>
            <xsl:when test="$profil/section/StructuralMap/structure_types/@nom != ''">
                <xsl:value-of select="$profil/section/StructuralMap/structure_types/@nom" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$parametres/section/StructuralMap/structure_types/@nom" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <!-- ==============================================================
    Template principal
    =============================================================== -->

    <xsl:template match="/refNum:refNum">
        <xsl:element name="mets">
            <xsl:namespace name="" select="'http://www.loc.gov/METS/'" />
            <xsl:namespace name="premis" select="'info:lc/xmlns/premis-v2'" />
            <xsl:namespace name="xsi" select="'http://www.w3.org/2001/XMLSchema-instance'" />
            <xsl:namespace name="dc" select="'http://purl.org/dc/elements/1.1/'" />
            <xsl:namespace name="xlink" select="'http://www.w3.org/1999/xlink'" />
            <xsl:namespace name="dcterms" select="'http://purl.org/dc/terms/'" />
            <xsl:for-each select="$parametres/racine/namespace | $profil/namespace">
                <xsl:namespace name="{@prefix}" select="." />
            </xsl:for-each>
            <!-- Mis seulement au niveau des opérations. -->
            <xsl:if test="$profil/section/AdministrativeMetadataSection/@remplir = 'true'
                and $profil/section/AdministrativeMetadataSection/digiprovMD/@remplir = 'true'
                and //detailsOperation:detailsOperation
                ">
                <xsl:namespace name="detailsOperation" select="'http://bibnum.bnf.fr/ns/detailsOperation'" />
            </xsl:if>

            <!-- Pas besoin d'ID à ce niveau. -->

            <xsl:if test="normalize-space(refNum:document/@identifiant) != ''">
                <xsl:attribute name="OBJID">
                    <xsl:value-of select="$parametres/racine/baseUrlObjId" />
                    <xsl:value-of select="normalize-space(refNum:document/@identifiant)" />
                </xsl:attribute>
            </xsl:if>

            <xsl:if test="normalize-space(refNum:document/refNum:bibliographie/refNum:titre)">
                <xsl:attribute name="LABEL">
                    <xsl:value-of select="normalize-space(refNum:document/refNum:bibliographie/refNum:titre)" />
                </xsl:attribute>
            </xsl:if>

            <xsl:variable name="genre" select="normalize-space(refNum:document/refNum:bibliographie/refNum:genre)" />
            <xsl:choose>
                <xsl:when test="$codes/genre/entry[@code = upper-case($genre)]">
                    <xsl:attribute name="TYPE">
                        <xsl:value-of select="$codes/genre/entry[@code = upper-case($genre)]" />
                    </xsl:attribute>
                </xsl:when>
                <xsl:when test="$genre != ''">
                    <xsl:attribute name="TYPE">
                        <xsl:value-of select="$genre" />
                    </xsl:attribute>
                </xsl:when>
            </xsl:choose>

            <xsl:if test="$profil/profile">
                <xsl:attribute name="PROFILE">
                    <xsl:value-of select="$profil/profile" />
                </xsl:attribute>
            </xsl:if>

            <xsl:if test="$profil/section/MetsHeader/@remplir = 'true'">
                <xsl:apply-templates select="." mode="MetsHeader" />
            </xsl:if>

            <xsl:if test="$profil/section/DescriptiveMetadataSection/@remplir = 'true'">
                <xsl:apply-templates select="." mode="DescriptiveMetadataSection" />
            </xsl:if>

            <xsl:if test="$profil/section/DescriptiveMetadataSection_fichiers/@remplir = 'true'">
                <xsl:apply-templates select="refNum:document/refNum:structure/refNum:vueObjet/refNum:*[name() = 'texte' or name() = 'image' or name() = 'audio']"
                    mode="DescriptiveMetadataSection" />
            </xsl:if>

            <xsl:if test="$profil/section/AdministrativeMetadataSection/@remplir = 'true'">
                <xsl:apply-templates select="." mode="AdministrativeMetadataSection" />
            </xsl:if>

            <xsl:if test="$profil/section/FileSection/@remplir = 'true'">
                <xsl:apply-templates select="." mode="FileSection" />
            </xsl:if>

            <!-- Obligatoire en Mets. -->
            <xsl:if test="$profil/section/StructuralMap/@remplir = 'true'">
                <xsl:apply-templates select="." mode="StructuralMap" />
            </xsl:if>

            <xsl:if test="$profil/section/StructuralLinks/@remplir = 'true'">
                <xsl:apply-templates select="." mode="StructuralLinks" />
            </xsl:if>

            <xsl:if test="$profil/section/Behavior/@remplir = 'true'">
                <xsl:apply-templates select="." mode="Behavior" />
            </xsl:if>
        </xsl:element>
    </xsl:template>

    <!-- ==============================================================
    Templates pour chacune des sept sections à remplir du Mets.
    =============================================================== -->

    <xsl:template match="/refNum:refNum" mode="MetsHeader">
        <xsl:element name="metsHdr">
            <xsl:attribute name="CREATEDATE">
                <xsl:value-of select="format-dateTime(
                    current-dateTime(),
                    '[Y0001]-[M01]-[D01]T[H01]:[m01]:[s01][z]')" />
            </xsl:attribute>
            <!-- On sous-entend que c'est complet. -->
            <!-- TODO Ajouter un check ? -->
            <xsl:attribute name="RECORDSTATUS">Complete</xsl:attribute>

            <xsl:copy-of select="$parametres/section/mets:MetsHeader/mets:agent" copy-namespaces="no" />

            <!-- Pas d'autre identifiant du document dans le refNum : <altRecordID TYPE="SUDOC">.-->

        </xsl:element>
    </xsl:template>

    <xsl:template match="/refNum:refNum" mode="DescriptiveMetadataSection">
        <!-- Préparation des variables liées à la tomaison, qui peuvent être
        reprises dans le titre ou la date pour les données descriptives. -->
        <xsl:variable name="tomaisonTitle">
            <xsl:apply-templates select="refNum:document/refNum:bibliographie/refNum:tomaison" />
        </xsl:variable>
        <xsl:variable name="tomaisonDate">
            <xsl:apply-templates select="refNum:document/refNum:bibliographie/refNum:tomaison
                [index-of($parametres//tomaisonTypes/date, lower-case(normalize-space(refNum:type))) > 0]" />
        </xsl:variable>

        <!-- Uniquement pour un périodique. -->
        <xsl:if test="$parametres/periodique/@remplir = 'true'">
            <xsl:element name="dmdSec">
                <xsl:attribute name="ID">
                    <!-- L'id principal d'un périodique est toujours "DMD.1". -->
                    <xsl:text>DMD.1</xsl:text>
                </xsl:attribute>

                <xsl:element name="mdRef">
                    <xsl:attribute name="LOCTYPE"><xsl:text>ARK</xsl:text></xsl:attribute>
                    <xsl:attribute name="xlink:type"><xsl:text>simple</xsl:text></xsl:attribute>
                    <xsl:attribute name="xlink:href">
                        <xsl:text>ark:/</xsl:text>
                        <xsl:value-of select="$parametres/ark/institution" />
                        <xsl:text>/</xsl:text>
                        <xsl:value-of select="$parametres/periodique/ark" />
                    </xsl:attribute>
                    <xsl:attribute name="MDTYPE"><xsl:text>DC</xsl:text></xsl:attribute>
                    <xsl:attribute name="MIMETYPE"><xsl:text>text/xml</xsl:text></xsl:attribute>
                </xsl:element>

            </xsl:element>
        </xsl:if>

        <xsl:element name="dmdSec">
            <xsl:attribute name="ID">
                <xsl:text>DMD.</xsl:text>
                <xsl:value-of select="1 + number($parametres/periodique/@remplir = 'true')" />
            </xsl:attribute>
            <xsl:element name="mdWrap">
                <xsl:attribute name="MIMETYPE">text/xml</xsl:attribute>
                <xsl:attribute name="MDTYPE">DC</xsl:attribute>
                <xsl:attribute name="LABEL">Notice du document</xsl:attribute>
                <xsl:element name="xmlData">
                    <xsl:element name="{$profil/section/DescriptiveMetadataSection/descriptiveFormatWrapper}">

                        <!-- Préparation de la notice du tableur pour le document. -->
                        <xsl:variable name="notice">
                            <xsl:if test="$profil/section/DescriptiveMetadataSection/metadata/@ordre != 'refnum'
                                and r2m:existeFichier('notices')">
                                <xsl:sequence select="r2m:trouveNotice(refNum:document/@identifiant)" />
                            </xsl:if>
                        </xsl:variable>

                        <xsl:choose>
                            <!-- Ajout des métadonnées de la table. -->
                            <xsl:when test="$profil/section/DescriptiveMetadataSection/metadata/@ordre = 'table'
                                    or ($profil/section/DescriptiveMetadataSection/metadata/@ordre = 'table sinon refnum'
                                        and r2m:existeFichier('notices'))
                                    ">
                                <xsl:sequence select="$notice" />
                            </xsl:when>

                            <!-- Ajout de chaque valeur selon l'ordre du Dublin Core à partir du refnum. -->
                            <xsl:otherwise>
                                <!-- dc:title -->
                                <!-- Plusieurs titres peuvent être séparés par des points-virgules. -->
                                <xsl:for-each select="tokenize(normalize-space(refNum:document/refNum:bibliographie/refNum:titre), ';')">
                                    <dc:title>
                                        <xsl:value-of select="normalize-space(.)" />
                                        <xsl:if test="position() = 1
                                            and $tomaisonTitle != ''
                                            and $profil/section/DescriptiveMetadataSection/tomaison/ajoutPremierTitre/@remplir = 'true'">
                                            <xsl:text> (</xsl:text>
                                            <xsl:value-of select="$tomaisonTitle" />
                                            <xsl:text>)</xsl:text>
                                        </xsl:if>
                                    </dc:title>
                                </xsl:for-each>
                                <xsl:if test="$tomaisonTitle != '' and $profil/section/DescriptiveMetadataSection/tomaison/ajoutAutreTitre/@remplir = 'true'">
                                    <dc:title>
                                        <xsl:value-of select="$tomaisonTitle" />
                                    </dc:title>
                                </xsl:if>
                                <xsl:call-template name="ajout_metadonnees">
                                    <xsl:with-param name="element" select="'dc:title'" />
                                </xsl:call-template>

                                <!-- dc:creator -->
                                <!-- Plusieurs auteurs peuvent être séparés par des points-virgules. -->
                                <xsl:for-each select="tokenize(normalize-space(refNum:document/refNum:bibliographie/refNum:auteur), ';')[normalize-space(.) != '']">
                                    <dc:creator>
                                        <xsl:value-of select="normalize-space(.)" />
                                    </dc:creator>
                                </xsl:for-each>
                                <xsl:call-template name="ajout_metadonnees">
                                    <xsl:with-param name="element" select="'dc:creator'" />
                                </xsl:call-template>

                                <!-- dc:subject -->
                                <xsl:for-each select="refNum:document/refNum:bibliographie/refNum:reference[@type = 'CADRECLASSEMENTDEWEY'][normalize-space(.) != '']">
                                    <dc:subject>
                                        <xsl:value-of select="normalize-space(.)" />
                                    </dc:subject>
                                </xsl:for-each>
                                <xsl:call-template name="ajout_metadonnees">
                                    <xsl:with-param name="element" select="'dc:subject'" />
                                </xsl:call-template>

                                <!-- dc:description -->
                                <xsl:for-each select="refNum:document/refNum:bibliographie/refNum:description[normalize-space(.) != '']">
                                    <dc:description>
                                        <xsl:value-of select="normalize-space(.)" />
                                    </dc:description>
                                </xsl:for-each>
                                <xsl:if test="$tomaisonTitle != ''">
                                    <xsl:if test="$profil/section/DescriptiveMetadataSection/tomaison/ajoutDescription/@remplir = 'true'">
                                        <dc:description>
                                            <xsl:value-of select="$tomaisonTitle" />
                                        </dc:description>
                                    </xsl:if>
                                    <xsl:if test="$profil/section/DescriptiveMetadataSection/tomaison/ajoutDescriptionSepare/@remplir = 'true'">
                                        <xsl:for-each select="refNum:document/refNum:bibliographie/refNum:tomaison">
                                            <xsl:element name="dc:description">
                                                <xsl:if test="$profil/section/DescriptiveMetadataSection/tomaison/attributes">
                                                    <xsl:attribute name="{$profil/section/DescriptiveMetadataSection/tomaison/attributes/@nom}">
                                                        <xsl:choose>
                                                            <xsl:when test="count($profil/section/DescriptiveMetadataSection/tomaison/attributes/attribute) > 1">
                                                                <xsl:variable name="position" select="position()" />
                                                                <xsl:value-of select="$profil/section/DescriptiveMetadataSection/tomaison/attributes/attribute
                                                                [position() = $position]" />
                                                            </xsl:when>
                                                            <xsl:otherwise>
                                                                <xsl:value-of select="$profil/section/DescriptiveMetadataSection/tomaison/attributes/attribute" />
                                                            </xsl:otherwise>
                                                        </xsl:choose>
                                                    </xsl:attribute>
                                                </xsl:if>
                                                <xsl:apply-templates select="." />
                                            </xsl:element>
                                        </xsl:for-each>
                                    </xsl:if>
                                </xsl:if>
                                <xsl:call-template name="ajout_metadonnees">
                                    <xsl:with-param name="element" select="'dc:description'" />
                                </xsl:call-template>

                                <!-- dc:publisher -->
                                <xsl:if test="normalize-space(refNum:document/refNum:bibliographie/refNum:editeur)">
                                    <dc:publisher>
                                        <xsl:value-of select="normalize-space(refNum:document/refNum:bibliographie/refNum:editeur)" />
                                    </dc:publisher>
                                </xsl:if>
                                <xsl:call-template name="ajout_metadonnees">
                                    <xsl:with-param name="element" select="'dc:publisher'" />
                                </xsl:call-template>

                                <!-- dc:contributor. -->
                                <xsl:call-template name="ajout_metadonnees">
                                    <xsl:with-param name="element" select="'dc:contributor'" />
                                </xsl:call-template>

                                <!-- dc:date (dcterms:issued) -->
                                <xsl:for-each select="refNum:document/refNum:bibliographie/refNum:dateEdition[normalize-space(.) != '']">
                                    <dc:date>
                                        <xsl:value-of select="normalize-space(.)" />
                                    </dc:date>
                                </xsl:for-each>
                                <xsl:if test="$tomaisonDate != '' and $profil/section/DescriptiveMetadataSection/tomaison/ajoutDate/@remplir = 'true'">
                                    <dc:date>
                                        <xsl:value-of select="$tomaisonDate" />
                                    </dc:date>
                                </xsl:if>
                                <xsl:call-template name="ajout_metadonnees">
                                    <xsl:with-param name="element" select="'dc:date'" />
                                </xsl:call-template>

                                <!-- dc:type -->
                                <!-- Utilisation de l'un des types standard, outre le type refNum. -->
                                <xsl:variable name="genre" select="normalize-space(refNum:document/refNum:bibliographie/refNum:genre)" />
                                <xsl:choose>
                                    <xsl:when test="$codes/genre/entry[@code = upper-case($genre)]">
                                        <dc:type>
                                            <xsl:value-of select="$codes/genre/entry[@code = upper-case($genre)]/@type" />
                                        </dc:type>
                                        <dc:type>
                                            <xsl:choose>
                                                <xsl:when test="$profil/section/DescriptiveMetadataSection/genreSelect != ''">
                                                    <xsl:value-of select="$codes/genre/entry[@code = upper-case($genre)]
                                                        /@*[name() = $profil/section/DescriptiveMetadataSection/genreSelect]" />
                                                </xsl:when>
                                                <xsl:otherwise>
                                                    <xsl:value-of select="$codes/genre/entry[@code = upper-case($genre)]" />
                                                </xsl:otherwise>
                                            </xsl:choose>
                                        </dc:type>
                                    </xsl:when>
                                    <!-- Variantes du standard. -->
                                    <xsl:otherwise>
                                        <xsl:if test="$genre != ''">
                                            <dc:type>
                                                <xsl:value-of select="$genre" />
                                            </dc:type>
                                        </xsl:if>
                                        <xsl:call-template name="ajout_metadonnees">
                                            <xsl:with-param name="element" select="'dc:type'" />
                                        </xsl:call-template>
                                    </xsl:otherwise>
                                </xsl:choose>

                                <!-- dc:format -->
                                <xsl:variable name="nombrePages" select="normalize-space(refNum:document/refNum:bibliographie/refNum:nombrePages)" />
                                <xsl:if test="$nombrePages != '' and lower-case($nombrePages) != 'sans objet'">
                                    <dc:format>
                                        <xsl:value-of select="$nombrePages" />
                                        <xsl:text> pages</xsl:text>
                                    </dc:format>
                                </xsl:if>
                                <xsl:call-template name="ajout_metadonnees">
                                    <xsl:with-param name="element" select="'dc:format'" />
                                </xsl:call-template>

                                <!-- dc:identifier -->
                                <xsl:if test="normalize-space(refNum:document/@identifiant) != ''">
                                    <dc:identifier>
                                        <xsl:value-of select="normalize-space(refNum:document/@identifiant)" />
                                    </dc:identifier>
                                </xsl:if>
                                <!-- TODO En section descriptive ou administrative ? -->
                                <xsl:if test="normalize-space(refNum:document/@numper) != ''">
                                    <dc:identifier>
                                        <xsl:text>Numper : </xsl:text>
                                        <xsl:value-of select="normalize-space(refNum:document/@numper)" />
                                    </dc:identifier>
                                </xsl:if>
                                <!-- TODO En section descriptive ou administrative ? -->
                                <xsl:if test="normalize-space(refNum:document/@identifiantAutreVersion) != ''">
                                    <dc:identifier>
                                        <xsl:text>Identifiant autre version : </xsl:text>
                                        <xsl:value-of select="normalize-space(refNum:document/@identifiantAutreVersion)" />
                                    </dc:identifier>
                                </xsl:if>
                                <!-- TODO En section descriptive ou administrative ? -->
                                <xsl:for-each select="refNum:document/refNum:bibliographie/refNum:reference[@type = 'IDDOCUMENT'][normalize-space(.) != '']">
                                    <dc:identifier>
                                        <xsl:text>ID document : </xsl:text>
                                        <xsl:value-of select="normalize-space(.)" />
                                    </dc:identifier>
                                </xsl:for-each>
                                <xsl:call-template name="ajout_metadonnees">
                                    <xsl:with-param name="element" select="'dc:identifier'" />
                                </xsl:call-template>

                                <!-- dc:source -->
                                <!-- Voir http://dublincore.org/documents/usageguide/elements.shtml#source -->
                                <xsl:for-each select="refNum:document/refNum:bibliographie/refNum:reference[@type = 'COTEORIGINAL'][normalize-space(.) != '']">
                                    <dc:source>
                                        <xsl:text>Cote original : </xsl:text>
                                        <xsl:value-of select="normalize-space(.)" />
                                    </dc:source>
                                </xsl:for-each>
                                <xsl:for-each select="refNum:document/refNum:bibliographie/refNum:reference[@type = 'COTEOBJETREPRODUIT'][normalize-space(.) != '']">
                                    <dc:source>
                                        <xsl:text>Cote objet reproduit : </xsl:text>
                                        <xsl:value-of select="normalize-space(.)" />
                                    </dc:source>
                                </xsl:for-each>
                                <xsl:for-each select="refNum:document/refNum:bibliographie/refNum:reference[@type = 'SOURCE'][normalize-space(.) != '']">
                                    <dc:source>
                                        <xsl:value-of select="normalize-space(.)" />
                                    </dc:source>
                                </xsl:for-each>
                                <xsl:call-template name="ajout_metadonnees">
                                    <xsl:with-param name="element" select="'dc:source'" />
                                </xsl:call-template>

                                <!-- dcterms:provenance -->
                                <xsl:call-template name="ajout_metadonnees">
                                    <xsl:with-param name="element" select="'dcterms:provenance'" />
                                </xsl:call-template>

                                <!-- dc:language -->
                                <xsl:call-template name="ajout_metadonnees">
                                    <xsl:with-param name="element" select="'dc:language'" />
                                </xsl:call-template>

                                <!-- dc:relation -->
                                <xsl:for-each select="refNum:document/refNum:bibliographie/refNum:reference[@type = 'NOTICEBIBLIOGRAPHIQUE'][normalize-space(.) != '']">
                                    <dc:relation>
                                        <xsl:value-of select="normalize-space(.)" />
                                    </dc:relation>
                                </xsl:for-each>
                                <!-- TODO En section descriptive ou administrative ? -->
                                <xsl:for-each select="refNum:document/refNum:bibliographie/refNum:reference[@type = 'CODEBARREBNF'][normalize-space(.) != '']">
                                    <dc:relation>
                                        <xsl:text>Code-barre BnF : </xsl:text>
                                        <xsl:value-of select="normalize-space(.)" />
                                    </dc:relation>
                                </xsl:for-each>
                                <xsl:call-template name="ajout_metadonnees">
                                    <xsl:with-param name="element" select="'dc:relation'" />
                                </xsl:call-template>

                                <!-- dc:coverage -->
                                <xsl:call-template name="ajout_metadonnees">
                                    <xsl:with-param name="element" select="'dc:coverage'" />
                                </xsl:call-template>

                                <!-- dc:rights -->
                                <xsl:call-template name="ajout_metadonnees">
                                    <xsl:with-param name="element" select="'dc:rights'" />
                                </xsl:call-template>
                            </xsl:otherwise>
                        </xsl:choose>

                    </xsl:element>
                </xsl:element>
            </xsl:element>
        </xsl:element>
    </xsl:template>

    <xsl:template match="refNum:vueObjet/refNum:*[name() = 'texte' or name() = 'image' or name() = 'audio']"
        mode="DescriptiveMetadataSection">
        <xsl:element name="dmdSec">
            <xsl:attribute name="ID">
                <xsl:text>DMD.</xsl:text>
                <xsl:value-of select="r2m:genereIndexDmd(position())" />
            </xsl:attribute>
            <xsl:element name="mdWrap">
                <xsl:attribute name="MIMETYPE">text/xml</xsl:attribute>
                <xsl:attribute name="MDTYPE">DC</xsl:attribute>
                <xsl:attribute name="LABEL">Notice de vue</xsl:attribute>
                <xsl:element name="xmlData">
                    <xsl:element name="{$profil/section/DescriptiveMetadataSection/descriptiveFormatWrapper}">
                        <!-- Préparation des métadonnées du tableur pour l'objet numérisé. -->
                        <xsl:variable name="metadata">
                            <xsl:variable name="href" select="r2m:adresseFichier(., 'master')" />
                            <!-- Trouve la ligne. -->
                            <xsl:sequence select="r2m:trouveMetadata($href)" />
                        </xsl:variable>

                        <!-- Détermination des titres et description depuis le refNum. -->
                        <!-- Les autres métadonnées utiles se trouvent au niveau
                        du document et le lien est fait au niveau de "fileSec". -->
                        <!-- TODO Texte et Audio -->

                        <!-- Préparation du titre depuis le refnum. -->
                        <xsl:variable name="refnum_titre">
                            <xsl:choose>
                                <xsl:when test="$profil/section/DescriptiveMetadataSection_fichiers
                                        /titre/copie/@valeur = 'orderLabel'">
                                    <xsl:variable name="valeur_titre"
                                    select="r2m:nomImage(., $profil/section/StructuralMap/orderLabel)" />
                                    <xsl:if test="$valeur_titre != ''">
                                        <xsl:element name="dc:title">
                                            <xsl:sequence select="r2m:attributPagination(.)" />
                                            <xsl:value-of select="$valeur_titre" />
                                        </xsl:element>
                                    </xsl:if>
                                </xsl:when>
                                <xsl:when test="$profil/section/DescriptiveMetadataSection_fichiers
                                        /title/copie/@valeur = 'label'">
                                    <xsl:variable name="valeur_titre"
                                    select="r2m:nomImage(., $profil/section/StructuralMap/label)" />
                                    <xsl:if test="$valeur_titre != ''">
                                        <xsl:element name="dc:title">
                                            <xsl:value-of select="$valeur_titre" />
                                        </xsl:element>
                                    </xsl:if>
                                </xsl:when>
                            </xsl:choose>
                        </xsl:variable>

                        <!-- Préparation de la description depuis le refnum. -->
                        <xsl:variable name="refnum_description">
                            <xsl:variable name="valeur_description" select="
                            r2m:nomImage(., $profil/section/StructuralMap
                                /*[local-name() = $profil/section/DescriptiveMetadataSection_fichiers
                                    /description/copie/@valeur
                                ])" />
                            <xsl:if test="$valeur_description != ''
                                and $valeur_description != $refnum_titre/dc:title/text()">
                                <xsl:element name="dc:description">
                                    <xsl:value-of select="$valeur_description" />
                                </xsl:element>
                            </xsl:if>
                        </xsl:variable>

                        <!-- Ajout du refnum (titre et description) et de la table selon l'option. -->
                        <xsl:choose>
                            <!-- Table seule. -->
                            <xsl:when test="$profil/section/DescriptiveMetadataSection_fichiers
                                    /metadata/@ordre = 'table seulement'">
                                <xsl:sequence select="$metadata" />
                            </xsl:when>

                            <!-- Refnum seul. -->
                            <xsl:when test="$profil/section/DescriptiveMetadataSection_fichiers
                                    /metadata/@ordre = 'refnum seulement'">
                                <xsl:sequence select="$refnum_titre" />
                                <xsl:sequence select="$refnum_description" />
                            </xsl:when>

                            <!-- Ajout systématique du refnum (titre et description), sauf doublon. -->
                            <xsl:when test="$profil/section/DescriptiveMetadataSection_fichiers
                                    /metadata/@ordre = 'refnum et table'">
                                <xsl:if test="not($metadata/dc:title = $refnum_titre)">
                                    <xsl:sequence select="$refnum_titre" />
                                </xsl:if>
                                <xsl:if test="not($metadata/dc:description = $refnum_description)">
                                    <xsl:sequence select="$refnum_description" />
                                </xsl:if>
                                <xsl:sequence select="$metadata" />
                            </xsl:when>

                            <!-- Ajout du refnum (titre et description) si non défini dans la table. -->
                            <xsl:when test="$profil/section/DescriptiveMetadataSection_fichiers
                                    /metadata/@ordre = 'table sinon refnum'">
                                <xsl:if test="not($metadata/dc:title)">
                                    <xsl:sequence select="$refnum_titre" />
                                </xsl:if>
                                <xsl:if test="not($metadata/dc:description)">
                                    <xsl:sequence select="$refnum_description" />
                                </xsl:if>
                                <xsl:sequence select="$metadata" />
                            </xsl:when>
                        </xsl:choose>
                    </xsl:element>
                </xsl:element>
            </xsl:element>
        </xsl:element>
    </xsl:template>

    <xsl:template match="/refNum:refNum" mode="AdministrativeMetadataSection">
        <xsl:element name="amdSec">
            <!-- Représentation Spar -->
            <xsl:if test="$profil/section/AdministrativeMetadataSection/spar/@remplir = 'true'">
                <xsl:apply-templates select="." mode="spar_techMD"/>
            </xsl:if>

            <!-- TechMD si souhaité, pour master et les objets associés. -->
            <xsl:if test="$profil/section/AdministrativeMetadataSection/techMD/@remplir = 'true'">
                <xsl:apply-templates select="refNum:document/refNum:structure/refNum:vueObjet/refNum:*[name() = 'texte' or name() = 'image' or name() = 'audio']"
                    mode="techMD">
                    <xsl:with-param name="objetAssocie" select="'master'" />
                </xsl:apply-templates>

                <xsl:for-each select="refNum:document/refNum:production/refNum:objetAssocie">
                    <xsl:apply-templates select="../../refNum:structure/refNum:vueObjet/refNum:*[name() = 'texte' or name() = 'image' or name() = 'audio']"
                        mode="techMD">
                        <xsl:with-param name="objetAssocie" select="." />
                    </xsl:apply-templates>
                </xsl:for-each>
            </xsl:if>

            <!-- TODO Non géré actuellement (et interdit de profil Mets Sip BnF). -->
            <xsl:if test="$profil/section/AdministrativeMetadataSection/rightsMD/@remplir = 'true'">
                <xsl:apply-templates select="." mode="rightsMD" />
            </xsl:if>

            <!-- Source est obligatoire pour Bnf. -->
            <xsl:if test="$profil/section/AdministrativeMetadataSection/sourceMD/@remplir = 'true'">
                <xsl:apply-templates select="." mode="sourceMD" />
            </xsl:if>

            <xsl:if test="$profil/section/AdministrativeMetadataSection/digiprovMD/@remplir = 'true'">
                <!-- Historique production. -->
                <xsl:apply-templates select="refNum:document/refNum:production/refNum:historique/refNum:traitement/refNum:operation"
                    mode="digiprovMD" />

                <!-- Commentaires structure, vue objet et fichier. -->
                <xsl:apply-templates select="refNum:document/refNum:structure//refNum:commentaire"
                    mode="digiprovMD" />
            </xsl:if>

            <!-- Infos initiales Spar -->
            <xsl:if test="$profil/section/AdministrativeMetadataSection/spar/@remplir = 'true'">
                <xsl:apply-templates select="." mode="spar_digiprovMD_init"/>
            </xsl:if>

            <xsl:if test="$profil/section/AdministrativeMetadataSection/digiprovMD/@remplir = 'true'">
                <!-- Contrôle de validité. -->
                <xsl:if test="$profil/section/AdministrativeMetadataSection/digiprovMD/valide/@remplir = 'true'">
                    <xsl:apply-templates select="refNum:document/refNum:structure/refNum:vueObjet/refNum:*[name() = 'texte' or name() = 'image' or name() = 'audio']"
                        mode="digiprovMD_valid">
                        <xsl:with-param name="objetAssocie" select="'master'" />
                    </xsl:apply-templates>

                    <xsl:for-each select="refNum:document/refNum:production/refNum:objetAssocie">
                        <xsl:apply-templates select="../../refNum:structure/refNum:vueObjet/refNum:*[name() = 'texte' or name() = 'image' or name() = 'audio']"
                            mode="digiprovMD_valid">
                            <xsl:with-param name="objetAssocie" select="." />
                        </xsl:apply-templates>
                    </xsl:for-each>
                </xsl:if>
            </xsl:if>

            <!-- Infos finales Spar -->
            <xsl:if test="$profil/section/AdministrativeMetadataSection/spar/@remplir = 'true'">
                <xsl:apply-templates select="." mode="spar_digiprovMD_fin"/>
            </xsl:if>
        </xsl:element>

    <!--
        // Production.
        $production = &$this->_xml->document->production;

        if (!empty($production->dateNumerisation)) {
            $doc['metadata']['Dublin Core']['Date'][] = 'Numérisation : ' . trim($production->dateNumerisation);
            // Added field.
            // $doc['metadata']['Item Type Metadata']['Date de numérisation'][] = trim($production->dateNumerisation);
        }

        if (!empty($production->nombreVueObjets)) {
            $doc['metadata']['Dublin Core']['Format'][] = 'Nombre de vues : ' . trim($production->nombreVueObjets);
        }

        if (!empty($production->nombreImages)) {
            $doc['metadata']['Dublin Core']['Format'][] = 'Nombre d’images : ' . trim($production->nombreImages);
        }

        if (!empty($production->identifiantSupport)) {
            $doc['metadata']['Dublin Core']['Identifier'][] = sprintf('Support de numérisation : %s%s',
                trim($production->identifiantSupport),
                empty($production->identifiantSupport['ordre']) ? '' : ' [' . trim($production->identifiantSupport['ordre']) . ']');
        }

        if (!empty($production->objetAssocie)) {
            $objetAssocies = array(
                'ADAPTATIF' => 'Adaptif',
                'ALTO' => 'ALTO',
                'EPUB' => 'epub',
                'EXTRAIT' => 'Extrait',
                'TDM' => 'Table des matières',
                'TUILES' => 'Tuiles',
                'TXT' => 'Texte',
            );
            $objetAssocie = trim($production->objetAssocie);
            $doc['metadata']['Dublin Core']['Format'][] = sprintf('Objet associé : %s%s',
                (isset($objetAssocies[$objetAssocie]) ? $objetAssocies[$objetAssocie] : $objetAssocie),
                (empty($production->objetAssocie['date']) ? '' : ' [' . $production->objetAssocie['date'] . ']'));
        }

        /*
        if (!empty($production->historique)) {
            $doc['metadata']['refNum']['Historique'][] = $production->historique->asXML();
        }
        */
    -->
    </xsl:template>

    <xsl:template match="refNum:vueObjet/refNum:*[name() = 'texte' or name() = 'image' or name() = 'audio']"
        mode="techMD">
        <xsl:param name="objetAssocie" select="'master'" />

        <xsl:if test="$profil/section/AdministrativeMetadataSection/techMD/meta/@remplir = 'true'">
            <xsl:apply-templates select="." mode="techMD_meta">
                <xsl:with-param name="objetAssocie" select="$objetAssocie" />
                <xsl:with-param name="numeroFichier" select="position()" />
            </xsl:apply-templates>
        </xsl:if>

        <xsl:if test="$profil/section/AdministrativeMetadataSection/techMD/info/@remplir = 'true'">
            <xsl:apply-templates select="." mode="techMD_info">
                <xsl:with-param name="objetAssocie" select="$objetAssocie" />
                <xsl:with-param name="numeroFichier" select="position()" />
            </xsl:apply-templates>
        </xsl:if>
    </xsl:template>

    <xsl:template match="refNum:vueObjet/refNum:*[name() = 'texte' or name() = 'image' or name() = 'audio']"
        mode="techMD_meta">
        <xsl:param name="objetAssocie" select="'master'" />
        <xsl:param name="numeroFichier" select="0" />

        <xsl:variable name="numeroId" select="r2m:genereIndexAmd('techMD_meta', $numeroFichier, $objetAssocie)" />
        <xsl:variable name="fileIdPart" select="r2m:fileIdPart($objetAssocie)" />
        <xsl:variable name="mimetype" select="r2m:mimetypeFichier(upper-case(@typeFichier), $objetAssocie)" />

        <xsl:element name="techMD">
            <xsl:attribute name="ID">
                <xsl:text>AMD.</xsl:text>
                <xsl:value-of select="$numeroId" />
            </xsl:attribute>

            <mdWrap MDTYPE="PREMIS:OBJECT" MIMETYPE="text/xml">
                <xmlData>
                    <premis:object xsi:type="premis:file">
                        <premis:objectIdentifier>
                            <premis:objectIdentifierType>
                                <xsl:text>metsIdentifier</xsl:text>
                            </premis:objectIdentifierType>
                            <premis:objectIdentifierValue>
                                <xsl:value-of select="$fileIdPart" />
                                <xsl:text>.</xsl:text>
                                <xsl:value-of select="$numeroFichier" />
                            </premis:objectIdentifierValue>
                        </premis:objectIdentifier>
                        <premis:objectCharacteristics>
                            <premis:compositionLevel>0</premis:compositionLevel>
                            <!-- TODO Le format est-il obligatoire dans Premis ? -->
                            <xsl:if test="$codes/formatPremis/entry[@code = $mimetype]">
                                <premis:format>
                                    <premis:formatDesignation>
                                        <premis:formatName>
                                            <xsl:value-of select="$mimetype" />
                                        </premis:formatName>
                                        <premis:formatVersion>
                                            <xsl:value-of select="$codes/formatPremis/entry[@code = $mimetype]/@version" />
                                        </premis:formatVersion>
                                    </premis:formatDesignation>
                                    <premis:formatRegistry>
                                        <premis:formatRegistryName>
                                            <xsl:value-of select="$codes/formatPremis/entry[@code = $mimetype]/@registryName" />
                                        </premis:formatRegistryName>
                                        <premis:formatRegistryKey>
                                            <xsl:value-of select="$codes/formatPremis/entry[@code = $mimetype]/@registryKey" />
                                        </premis:formatRegistryKey>
                                    </premis:formatRegistry>
                                </premis:format>
                            </xsl:if>
                        </premis:objectCharacteristics>
                        <premis:storage>
                            <premis:storageMedium>
                                <xsl:text>SPAR storage unit</xsl:text>
                            </premis:storageMedium>
                        </premis:storage>
                    </premis:object>
                </xmlData>
            </mdWrap>

        </xsl:element>
    </xsl:template>

    <xsl:template match="refNum:vueObjet/refNum:*[name() = 'texte' or name() = 'image' or name() = 'audio']"
        mode="techMD_info">
        <xsl:param name="objetAssocie" select="'master'" />
        <xsl:param name="numeroFichier" select="0" />

        <xsl:variable name="numeroId" select="r2m:genereIndexAmd('techMD_info', $numeroFichier, $objetAssocie)" />

        <xsl:element name="techMD">
            <xsl:attribute name="ID">
                <xsl:text>AMD.</xsl:text>
                <xsl:value-of select="$numeroId" />
            </xsl:attribute>

            <xsl:variable name="type" select="name()" />

            <xsl:variable name="format">
                <xsl:choose>
                    <xsl:when test="$objetAssocie = '' or $objetAssocie = 'master'">
                        <xsl:value-of select="$parametres/section/AdministrativeMetadataSection/techMD/format/*[name() = $type]" />
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$codes/objetAssocie/entry[@code = $objetAssocie]/@code" />
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>

            <xsl:choose>
                <!-- Format par défaut : copie du refNum. -->
                <xsl:when test="$format = ''">
                    <xsl:apply-templates select="." mode="refNum" />
                </xsl:when>

                <xsl:when test="$format = 'NISOIMG'">
                    <xsl:apply-templates select="." mode="NISOIMG">
                        <xsl:with-param name="objetAssocie" select="$objetAssocie" />
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:when test="$format = 'MIX'">
                    <xsl:apply-templates select="." mode="MIX" />
                </xsl:when>

                <xsl:when test="$format = 'ADAPTATIF'">
                    <xsl:apply-templates select="." mode="reference">
                        <xsl:with-param name="format" select="$format" />
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:when test="$format = 'ALTO'">
                    <xsl:apply-templates select="." mode="ALTO" />
                </xsl:when>
                <xsl:when test="$format = 'EPUB'">
                    <xsl:apply-templates select="." mode="reference">
                        <xsl:with-param name="format" select="$format" />
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:when test="$format = 'EXTRAIT'">
                    <xsl:apply-templates select="." mode="reference">
                        <xsl:with-param name="format" select="$format" />
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:when test="$format = 'TDM'">
                    <xsl:apply-templates select="." mode="reference">
                        <xsl:with-param name="format" select="$format" />
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:when test="$format = 'TUILES'">
                    <xsl:apply-templates select="." mode="reference">
                        <xsl:with-param name="format" select="$format" />
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:when test="$format = 'TXT'">
                    <xsl:apply-templates select="." mode="reference">
                        <xsl:with-param name="format" select="$format" />
                    </xsl:apply-templates>
                </xsl:when>
            </xsl:choose>

        </xsl:element>
    </xsl:template>

    <xsl:template match="refNum:vueObjet/refNum:*[name() = 'texte' or name() = 'image' or name() = 'audio']"
        mode="refNum">
        <mdWrap MDTYPE="OTHER" OTHERMDTYPE="refNum" MIMETYPE="text/xml" LABEL="refNum {name()} data">
            <xmlData>
                <xsl:element name="{name()}">
                    <xsl:copy-of select="@*" />
                </xsl:element>
            </xmlData>
        </mdWrap>
    </xsl:template>

    <xsl:template match="refNum:vueObjet/refNum:*[name() = 'texte' or name() = 'image' or name() = 'audio']"
        mode="reference">
        <xsl:param name="format" select="''" />

        <mdRef MDTYPE="OTHER" OTHERMDTYPE="{$format}" MIMETYPE="text/xml" LABEL="refNum {name()} data" LOCTYPE="OTHER" OTHERLOCTYPE="fileid" xlink:href="{r2m:adresseFichier(., $format)}" />
    </xsl:template>

    <xsl:template match="refNum:vueObjet/refNum:image"
        mode="NISOIMG">
        <xsl:param name="objetAssocie" select="'master'" />

        <!-- Résolution et dimension ne sont pas des éléments obligatoires dans le refNum. -->
        <xsl:variable name="dimensionX" select="r2m:extractionXY(@dimension, 'X')" />
        <xsl:variable name="dimensionY" select="r2m:extractionXY(@dimension, 'Y')" />
        <xsl:variable name="resolutionX" select="r2m:extractionXY(@resolution, 'X')" />
        <xsl:variable name="resolutionY" select="r2m:extractionXY(@resolution, 'Y')" />
        <xsl:variable name="tailleX" select="r2m:dimensionSelonUnite($dimensionX, $resolutionX)" />
        <xsl:variable name="tailleY" select="r2m:dimensionSelonUnite($dimensionY, $resolutionY)" />
        <xsl:variable name="format" select="r2m:mimetypeFichier(@typeFichier, $objetAssocie)" />
        <xsl:variable name="byteOrder" select="r2m:byteOrderFichier(@typeFichier, $objetAssocie)" />

        <mdWrap MDTYPE="NISOIMG" MIMETYPE="text/xml" LABEL="NISO Image Data">
            <xmlData>
                <xsl:if test="$tailleX > 0">
                    <niso:sourceXDimensionValue>
                        <xsl:value-of select="$tailleX" />
                    </niso:sourceXDimensionValue>
                    <niso:sourceXDimensionUnit>
                        <xsl:value-of select="$parametres/section/AdministrativeMetadataSection/techMD/uniteSource" />
                    </niso:sourceXDimensionUnit>
                </xsl:if>

                <xsl:if test="$tailleY > 0">
                    <niso:sourceYDimensionValue>
                        <xsl:value-of select="$tailleY" />
                    </niso:sourceYDimensionValue>
                    <niso:sourceYDimensionUnit>
                        <xsl:value-of select="$parametres/section/AdministrativeMetadataSection/techMD/uniteSource" />
                    </niso:sourceYDimensionUnit>
                </xsl:if>

                <xsl:if test="$dimensionX > 0">
                    <niso:imageWidth>
                        <xsl:value-of select="$dimensionX" />
                    </niso:imageWidth>
                </xsl:if>

                <xsl:if test="$dimensionY > 0">
                    <niso:imageHeight>
                        <xsl:value-of select="$dimensionY" />
                    </niso:imageHeight>
                </xsl:if>

                <niso:samplingFrequencyUnit>
                    <xsl:choose>
                        <xsl:when test="$parametres/section/AdministrativeMetadataSection/techMD/uniteResolution = 'pouce'">
                            <xsl:text>2</xsl:text>
                        </xsl:when>
                        <xsl:when test="$parametres/section/AdministrativeMetadataSection/techMD/uniteResolution = 'cm'">
                            <xsl:text>3</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:text>1</xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                </niso:samplingFrequencyUnit>

                <xsl:if test="$resolutionX > 0">
                    <niso:xSamplingFrequency>
                        <xsl:value-of select="$resolutionX" />
                    </niso:xSamplingFrequency>
                </xsl:if>

                <xsl:if test="$resolutionY > 0">
                    <niso:ySamplingFrequency>
                        <xsl:value-of select="$resolutionY" />
                    </niso:ySamplingFrequency>
                </xsl:if>

                <xsl:if test="@profondeur">
                    <!-- Selon le format, cela peut être du type "8" ou du type "8,8,8". -->
                    <niso:bitsPerSampleValue>
                        <xsl:value-of select="@profondeur" />
                    </niso:bitsPerSampleValue>
                    <!-- Ajouter les unités, qui varient selon les images. -->
                    <!--
                    <niso:bitsPerSampleUnit>integer</niso:bitsPerSampleUnit>
                    <niso:samplesPerPixel>3</niso:samplesPerPixel>
                    -->
                </xsl:if>

                <xsl:if test="$format != ''">
                    <niso:formatName>
                        <xsl:value-of select="$format" />
                    </niso:formatName>
                </xsl:if>

                <xsl:if test="$byteOrder != ''">
                    <niso:byteOrder>
                        <xsl:value-of select="$byteOrder" />
                    </niso:byteOrder>
                </xsl:if>

                <xsl:if test="$parametres/section/AdministrativeMetadataSection/techMD/info/orientation">
                    <niso:orientation>
                        <xsl:value-of select="$parametres/section/AdministrativeMetadataSection/techMD/info/orientation" />
                    </niso:orientation>
                </xsl:if>

                <xsl:if test="$parametres/section/AdministrativeMetadataSection/techMD/info/producteur">
                    <niso:imageProducer>
                        <xsl:value-of select="$parametres/section/AdministrativeMetadataSection/techMD/info/producteur" />
                    </niso:imageProducer>
                </xsl:if>

                <xsl:if test="$parametres/section/AdministrativeMetadataSection/techMD/info/prestataire">
                    <niso:processingAgency>
                        <xsl:value-of select="$parametres/section/AdministrativeMetadataSection/techMD/info/prestataire" />
                    </niso:processingAgency>
                </xsl:if>

            </xmlData>
        </mdWrap>
    </xsl:template>

    <!-- TODO Format MIX non finalisé et nécessite informations extérieures sur l'image. -->
    <xsl:template match="refNum:vueObjet/refNum:image"
        mode="MIX">
        <xsl:param name="objetAssocie" select="'master'" />

        <!-- Résolution et dimension ne sont pas des éléments obligatoires dans le refNum. -->
        <xsl:variable name="dimensionX" select="r2m:extractionXY(@dimension, 'X')" />
        <xsl:variable name="dimensionY" select="r2m:extractionXY(@dimension, 'Y')" />
        <xsl:variable name="resolutionX" select="r2m:extractionXY(@resolution, 'X')" />
        <xsl:variable name="resolutionY" select="r2m:extractionXY(@resolution, 'Y')" />
        <xsl:variable name="tailleX" select="r2m:dimensionSelonUnite($dimensionX, $resolutionX)" />
        <xsl:variable name="tailleY" select="r2m:dimensionSelonUnite($dimensionY, $resolutionY)" />
        <xsl:variable name="format" select="r2m:mimetypeFichier(@typeFichier, $objetAssocie)" />
        <xsl:variable name="byteOrder" select="r2m:byteOrderFichier(@typeFichier, $objetAssocie)" />

        <mdWrap MDTYPE="NISOIMG" MIMETYPE="text/xml" LABEL="NISO image data">
            <xmlData>
                <!-- Exemple "complet" (le namespace peut être mis en entête). -->
                <mix:mix xmlns:mix="http://www.loc.gov/mix/v10">
                    <mix:BasicDigitalObjectInformation>
                        <mix:byteOrder><xsl:value-of select="$byteOrder" /></mix:byteOrder>
                        <mix:Compression>
                            <mix:compressionScheme>4</mix:compressionScheme>
                        </mix:Compression>
                    </mix:BasicDigitalObjectInformation>

                    <mix:BasicImageInformation>
                        <mix:BasicImageCharacteristics>
                            <mix:imageWidth>
                                <xsl:value-of select="$tailleX" />
                            </mix:imageWidth>
                            <mix:imageHeight>
                                <xsl:value-of select="$tailleY" />
                            </mix:imageHeight>
                            <mix:PhotometricInterpretation>
                                <mix:colorSpace>0</mix:colorSpace>
                            </mix:PhotometricInterpretation>
                        </mix:BasicImageCharacteristics>
                    </mix:BasicImageInformation>

                    <mix:ImageCaptureMetadata>
                        <mix:GeneralCaptureInformation>
                            <mix:dateTimeCreated>2010-04-27T08:24:26</mix:dateTimeCreated>
                            <mix:imageProducer>
                                <xsl:value-of select="$parametres/section/AdministrativeMetadataSection/techMD/imageProducer" />
                            </mix:imageProducer>
                        </mix:GeneralCaptureInformation>
                        <mix:ScannerCapture>
                            <mix:ScannerModel>
                                <mix:scannerModelName>k1</mix:scannerModelName>
                            </mix:ScannerModel>
                            <mix:ScanningSystemSoftware>
                                <mix:scanningSoftwareName>Spi.Factory</mix:scanningSoftwareName>
                            </mix:ScanningSystemSoftware>
                        </mix:ScannerCapture>
                        <mix:orientation>1</mix:orientation>
                    </mix:ImageCaptureMetadata>

                    <mix:ImageAssessmentMetadata>
                        <mix:SpatialMetrics>
                            <mix:samplingFrequencyUnit>2</mix:samplingFrequencyUnit>
                            <mix:xSamplingFrequency>
                                <mix:numerator>629145600</mix:numerator>
                                <mix:denominator>2097152</mix:denominator>
                            </mix:xSamplingFrequency>
                            <mix:ySamplingFrequency>
                                <mix:numerator>629145600</mix:numerator>
                                <mix:denominator>2097152</mix:denominator>
                            </mix:ySamplingFrequency>
                        </mix:SpatialMetrics>
                        <mix:ImageColorEncoding>
                            <mix:bitsPerSample>
                                <mix:bitsPerSampleValue>
                                    <xsl:value-of select="@profondeur" />
                                </mix:bitsPerSampleValue>
                                <mix:bitsPerSampleUnit>integer</mix:bitsPerSampleUnit>
                            </mix:bitsPerSample>
                            <mix:samplesPerPixel>1</mix:samplesPerPixel>
                        </mix:ImageColorEncoding>
                    </mix:ImageAssessmentMetadata>
                </mix:mix>

                <!-- Exemple de Mets (le namespace peut être mis en entête). -->
                <mix:mix xmlns:mix="http://www.loc.gov/mix/v10">
                    <mix:BasicImageParameters>
                        <mix:Format>
                            <mix:MIMEType>image/gif</mix:MIMEType>
                            <mix:ByteOrder>little-endian</mix:ByteOrder>
                            <mix:Compression>
                                <mix:CompressionScheme>5</mix:CompressionScheme>
                            </mix:Compression>
                            <mix:PhotometricInterpretation>
                                <mix:ColorSpace>3</mix:ColorSpace>
                            </mix:PhotometricInterpretation>
                        </mix:Format>
                        <mix:File>
                            <mix:Orientation>1</mix:Orientation>
                        </mix:File>
                    </mix:BasicImageParameters>

                    <mix:ImageCreation>
                    </mix:ImageCreation>

                    <mix:ImagingPerformanceAssessment>
                        <mix:SpatialMetrics>
                            <mix:ImageWidth>126</mix:ImageWidth>
                            <mix:ImageLength>216</mix:ImageLength>
                        </mix:SpatialMetrics>
                        <mix:Energetics>
                            <mix:BitsPerSample>8</mix:BitsPerSample>
                        </mix:Energetics>
                    </mix:ImagingPerformanceAssessment>
                </mix:mix>

            </xmlData>
        </mdWrap>
    </xsl:template>

    <xsl:template match="refNum:vueObjet/refNum:image"
        mode="ALTO">

        <mdWrap MDTYPE="TEXTMD" MIMETYPE="text/xml">
            <xmlData>
                <xsl:apply-templates select="$parametres/formatsObjetsAssocies/entry[@code = 'ALTO']/*"
                    mode="copy-prefix">
                    <xsl:with-param name="prefix" select="'textmd'" />
                </xsl:apply-templates>
            </xmlData>
        </mdWrap>
    </xsl:template>

    <xsl:template match="/refNum:refNum" mode="rightsMD">
        <xsl:element name="rightsMD">
            <xsl:attribute name="ID">
                <xsl:text>AMD.</xsl:text>
                <xsl:value-of select="r2m:genereIndexAmd('rightsMD', 0, '')" />
            </xsl:attribute>
        </xsl:element>
    </xsl:template>

    <xsl:template match="/refNum:refNum" mode="sourceMD">
        <xsl:element name="sourceMD">
            <xsl:attribute name="ID">
                <xsl:text>AMD.</xsl:text>
                <xsl:value-of select="r2m:genereIndexAmd('sourceMD', 0, '')" />
            </xsl:attribute>

            <xsl:element name="mdWrap">
                <xsl:attribute name="MIMETYPE">text/xml</xsl:attribute>
                <xsl:attribute name="MDTYPE">DC</xsl:attribute>
                <xsl:attribute name="LABEL">Notice administrative Dublin Core</xsl:attribute>
                <xsl:element name="xmlData">
                    <xsl:element name="{$profil/section/DescriptiveMetadataSection/descriptiveFormatWrapper}">

                        <!-- A la BnF, le format de la source est en "description",
                        pas en "format" ou "Medium". -->
                        <!-- dc:description -->
                        <xsl:for-each-group select="refNum:document/refNum:structure/refNum:vueObjet/refNum:*[name() = 'texte' or name() = 'image' or name() = 'audio']"
                            group-by="@supportOrigine">
                            <dc:description xml:lang="fr">
                                <xsl:value-of select="$codes/supportOrigine/entry[@code = current()/@supportOrigine]" />
                            </dc:description>
                        </xsl:for-each-group>

                        <!-- dc:identifier -->
                        <xsl:for-each select="refNum:document/refNum:bibliographie/refNum:reference[@type = 'CODEBARREPROVENANCE'][normalize-space(.) != '']">
                            <xsl:element name="dc:identifier">
                                <xsl:if test="$profil/section/AdministrativeMetadataSection/sourceMD/codeBarreSelect">
                                    <xsl:attribute name="xsi:type">
                                        <xsl:value-of select="$profil/section/AdministrativeMetadataSection/sourceMD/codeBarreSelect" />
                                    </xsl:attribute>
                                </xsl:if>
                                <xsl:value-of select="normalize-space(.)" />
                            </xsl:element>
                        </xsl:for-each>

                    </xsl:element>
                </xsl:element>
            </xsl:element>
        </xsl:element>
    </xsl:template>

    <xsl:template match="refNum:operation"
        mode="digiprovMD">

        <xsl:variable name="numeroId" select="r2m:genereIndexAmd('digiprovMD', position(), '')" />

        <xsl:element name="digiprovMD">
            <xsl:attribute name="ID">
                <xsl:text>AMD.</xsl:text>
                <xsl:value-of select="$numeroId" />
            </xsl:attribute>

            <xsl:element name="mdWrap">
                <xsl:attribute name="MIMETYPE">text/xml</xsl:attribute>
                <xsl:attribute name="MDTYPE">PREMIS:EVENT</xsl:attribute>

                <xmlData>
                    <premis:event>
                        <xsl:call-template name="premisEventIdentifier">
                            <xsl:with-param name="partie" select="'digiprovMD'" />
                            <xsl:with-param name="numeroId" select="$numeroId" />
                        </xsl:call-template>

                        <premis:eventType>
                            <xsl:value-of select="$codes/operationType/entry[@code = current()/@type]/@premis" />
                        </premis:eventType>

                        <!-- Cet élément est requis selon le refNum. La date de
                        fin peut être ajoutée dans les détails. -->
                        <xsl:if test="refNum:entree/@date">
                            <premis:eventDateTime>
                                <xsl:value-of select="refNum:entree/@date" />
                            </premis:eventDateTime>
                        </xsl:if>

                            <premis:eventDetail>
                            <xsl:for-each select="../../refNum:traitement/@*">
                                <xsl:value-of select="$codes/traitement/entry[@code = name(current())]/@premis" />
                                <xsl:text>=</xsl:text>
                                <xsl:value-of select="." />
                                <xsl:if test="position() != last()">
                                    <xsl:text>; </xsl:text>
                                </xsl:if>
                            </xsl:for-each>
                            <xsl:if test="@ordre">
                                <xsl:if test="count(../../refNum:traitement/@*)">
                                    <xsl:text>; </xsl:text>
                                </xsl:if>
                                <xsl:value-of select="$codes/operation/entry[@code = 'ordre']/@premis" />
                                <xsl:text>=</xsl:text>
                                <xsl:value-of select="@ordre" />
                            </xsl:if>
                        </premis:eventDetail>

                        <!-- Traitement des opérations refNum (entrée, éventuellement
                        description, et résultat. -->
                        <xsl:apply-templates select="refNum:*" />

                        <!-- Traitement des agents refNum avec detailsOperation. -->
                        <xsl:for-each-group select="refNum:*/detailsOperation:detailsOperation/detailsOperation:agent"
                            group-by="." >
                            <premis:linkingAgentIdentifier>
                                <premis:linkingAgentIdentifierType>producerIdentifier</premis:linkingAgentIdentifierType>
                                <premis:linkingAgentIdentifierValue>
                                    <xsl:value-of select="." />
                                </premis:linkingAgentIdentifierValue>
                                <premis:linkingAgentRole>
                                    <xsl:value-of select="$codes/agent/entry[@code = 'agentOperation']/@premis " />
                                </premis:linkingAgentRole>
                            </premis:linkingAgentIdentifier>
                        </xsl:for-each-group>

                        <!-- Ajout des agents de traitement. -->
                        <xsl:for-each select="../refNum:*[name() = 'agentAutorisation' or name() = 'agentOperation']">
                            <premis:linkingAgentIdentifier>
                                <premis:linkingAgentIdentifierType>producerIdentifier</premis:linkingAgentIdentifierType>
                                <premis:linkingAgentIdentifierValue>
                                    <xsl:value-of select="." />
                                </premis:linkingAgentIdentifierValue>
                                <premis:linkingAgentRole>
                                    <xsl:value-of select="$codes/agent/entry[@code = name(current())]/@premis " />
                                </premis:linkingAgentRole>
                            </premis:linkingAgentIdentifier>
                        </xsl:for-each>

                    </premis:event>
                </xmlData>
            </xsl:element>
        </xsl:element>
    </xsl:template>

    <xsl:template match="refNum:structure//refNum:commentaire"
        mode="digiprovMD">

        <xsl:variable name="numeroId" select="r2m:genereIndexAmd('digiprovMD_structure', position(), '')" />

        <xsl:element name="digiprovMD">
            <xsl:attribute name="ID">
                <xsl:text>AMD.</xsl:text>
                <xsl:value-of select="$numeroId" />
            </xsl:attribute>

            <xsl:element name="mdWrap">
                <xsl:attribute name="MIMETYPE">text/xml</xsl:attribute>
                <xsl:attribute name="MDTYPE">PREMIS:EVENT</xsl:attribute>

                <xmlData>
                    <premis:event>
                        <xsl:call-template name="premisEventIdentifier">
                            <xsl:with-param name="partie" select="'digiprovMD_structure'" />
                            <xsl:with-param name="numeroId" select="$numeroId" />
                        </xsl:call-template>

                        <premis:eventType>
                            <xsl:value-of select="$codes/operationTypeCommentaire/entry[@code = current()/@type]/@premis" />
                        </premis:eventType>

                        <premis:eventDateTime>
                            <xsl:value-of select="@date" />
                        </premis:eventDateTime>

                        <!-- Dans l'exemple BnF, il n'y a qu'une seule opération par commentaire
                        et l'eventDetail correspond à la description de cette opération. -->
                        <xsl:choose>
                            <xsl:when test="detailsOperation:detailsOperation/detailsOperation:description">
                                <premis:eventDetail>
                                    <xsl:value-of select="$codes/detailsOperation/description/entry[@code = current()/detailsOperation:detailsOperation/detailsOperation:description]" />
                                </premis:eventDetail>
                            </xsl:when>
                            <xsl:otherwise>
                                <premis:eventDetail>
                                    <xsl:text></xsl:text>
                                </premis:eventDetail>
                            </xsl:otherwise>
                        </xsl:choose>

                        <!-- Traitement des opérations refNum (entrée, éventuellement
                        description, et résultat. -->
                        <xsl:apply-templates select="." />

                        <!-- Traitement des agents refNum avec detailsOperation. -->
                        <xsl:for-each-group select="detailsOperation:detailsOperation/detailsOperation:agent"
                            group-by="." >
                            <premis:linkingAgentIdentifier>
                                <premis:linkingAgentIdentifierType>producerIdentifier</premis:linkingAgentIdentifierType>
                                <premis:linkingAgentIdentifierValue>
                                    <xsl:value-of select="." />
                                </premis:linkingAgentIdentifierValue>
                                <premis:linkingAgentRole>
                                    <xsl:value-of select="$codes/agent/entry[@code = 'agent']/@premis " />
                                </premis:linkingAgentRole>
                            </premis:linkingAgentIdentifier>
                        </xsl:for-each-group>

                        <!-- Ajout du lien vers l'objet. -->
                        <premis:linkingObjectIdentifier>
                            <premis:linkingObjectIdentifierType>productionIdentifier</premis:linkingObjectIdentifierType>
                            <premis:linkingObjectIdentifierValue>
                                <xsl:value-of select="ancestor::refNum:document/@identifiant" />
                            </premis:linkingObjectIdentifierValue>
                        </premis:linkingObjectIdentifier>
                    </premis:event>
                </xmlData>
            </xsl:element>
        </xsl:element>
    </xsl:template>

    <!-- Pour entrée, description et résultat. -->
    <xsl:template match="refNum:entree | refNum:description | refNum:resultat | refNum:commentaire">
        <xsl:choose>
            <xsl:when test="detailsOperation:detailsOperation">
                <xsl:apply-templates select="detailsOperation:detailsOperation" />
            </xsl:when>

            <!-- L'exemple de la BnF utilise seulement certains sous-éléments
            de detailsOperation pour le résultat. La logique est élargie aux autres
            opérations possibles. -->
            <xsl:when test="detailsOperation:*">
                <xsl:apply-templates select="."  mode="detailsOperation"/>
            </xsl:when>

            <!-- Il y a des enfants, c'est donc un format inconnu. -->
            <xsl:when test="*">
                <!--
                <xsl:apply-templates select="." mode="children" />
                -->
                <xsl:apply-templates select="." mode="autre" />
            </xsl:when>

            <!-- Simple commentaire. -->
            <xsl:when test="normalize-space(text()) != ''">
                <xsl:apply-templates select="." mode="commentaire" />
            </xsl:when>

            <!-- Simple info sur le type ou la date. -->
            <xsl:when test="@*">
                <xsl:apply-templates select="." mode="commentaire-vide" />
            </xsl:when>
        </xsl:choose>
    </xsl:template>

    <!-- Conçu sur le modèle des résultats de l'exemple BnF. -->
    <xsl:template match="refNum:entree | refNum:description | refNum:resultat | refNum:commentaire"
        mode="detailsOperation">
        <xsl:variable name="operationElement" select="name()" />
        <premis:eventOutcomeInformation>
            <premis:eventOutcome>
                <xsl:value-of select="$codes/operationElement
                    /entry[@code = name(current())]/@premis" />
            </premis:eventOutcome>
            <xsl:if test="$parametres/section/AdministrativeMetadataSection/digiprovMD/ajouterDate
                    /*[name() = name(current())]/@remplir = 'true'">
                <premis:eventOutcomeDetail>
                    <premis:eventOutcomeDetailNote>
                        <xsl:value-of select="$parametres/section/AdministrativeMetadataSection/digiprovMD/ajouterDate
                            /*[name() = name(current())]" />
                        <xsl:value-of select="@date" />
                    </premis:eventOutcomeDetailNote>
                </premis:eventOutcomeDetail>
            </xsl:if>
            <xsl:for-each select="child::*">
                <premis:eventOutcomeDetail>
                    <premis:eventOutcomeDetailNote>
                        <xsl:value-of select="$codes
                            /detailsOperation
                            /*[name() = $operationElement]
                            /entry[@code = current()/@type]
                            " />
                        <xsl:text> : </xsl:text>
                        <xsl:value-of select="." />
                    </premis:eventOutcomeDetailNote>
                </premis:eventOutcomeDetail>
            </xsl:for-each>
        </premis:eventOutcomeInformation>
    </xsl:template>

    <!-- Copie d'un simple texte d'une entrée / description / résultat. -->
    <!-- TODO Aucun exemple, donc à vérifier. -->
    <xsl:template match="refNum:entree | refNum:description | refNum:resultat | refNum:commentaire"
        mode="commentaire">
        <premis:eventOutcomeInformation>
            <premis:eventOutcome>
                <xsl:choose>
                    <xsl:when test="$parametres/section/AdministrativeMetadataSection/digiprovMD/ajouterType
                        /*[name() = name(current())]/@remplir = 'true'">
                        <xsl:value-of select="$codes/operationElement
                            /entry[@code = name(current())]
                            /@premis" />
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$codes/operationElement
                            /entry[@code = name(current())]
                            /@premis" />
                    </xsl:otherwise>
                </xsl:choose>
            </premis:eventOutcome>
            <xsl:if test="$parametres/section/AdministrativeMetadataSection/digiprovMD/ajouterDate
                    /*[name() = name(current())]/@remplir = 'true'">
                <premis:eventOutcomeDetail>
                    <premis:eventOutcomeDetailNote>
                        <xsl:value-of select="$parametres/section/AdministrativeMetadataSection/digiprovMD/ajouterDate
                            /*[name() = name(current())]" />
                        <xsl:value-of select="@date" />
                    </premis:eventOutcomeDetailNote>
                </premis:eventOutcomeDetail>
            </xsl:if>
            <xsl:if test="normalize-space(.) != ''">
                <premis:eventOutcomeDetail>
                    <premis:eventOutcomeDetailNote>
                        <xsl:value-of select="normalize-space(.)" />
                    </premis:eventOutcomeDetailNote>
                </premis:eventOutcomeDetail>
            </xsl:if>
        </premis:eventOutcomeInformation>
    </xsl:template>

    <!-- Copie des attributs d'une entrée / description / résultat vide. -->
    <xsl:template match="refNum:entree | refNum:description | refNum:resultat | refNum:commentaire"
        mode="commentaire-vide">
        <xsl:if test="$parametres/section/AdministrativeMetadataSection/digiprovMD/ajouterType
                /*[name() = name(current())]/@remplir = 'true'
            or
            $parametres/section/AdministrativeMetadataSection/digiprovMD/ajouterDate
                /*[name() = name(current())]/@remplir = 'true'
            ">

            <xsl:apply-templates select="." mode="commentaire" />

        </xsl:if>
    </xsl:template>

    <!-- Copie les formats inconnus des entrées / descriptions / résultats des opérations. -->
    <!-- TODO Aucun exemple, donc à vérifier. -->
    <xsl:template match="refNum:entree | refNum:description | refNum:resultat | refNum:commentaire"
        mode="autre">
        <premis:eventOutcomeInformation>
            <premis:eventOutcome>
                <xsl:value-of select="$codes/operationElement
                    /entry[@code = name(current())]
                    /@premis" />
            </premis:eventOutcome>
            <premis:eventOutcomeDetail>
                <premis:eventOutcomeDetailExtension>
                <xsl:copy-of select="." copy-namespaces="no" />
                </premis:eventOutcomeDetailExtension>
            </premis:eventOutcomeDetail>
        </premis:eventOutcomeInformation>
    </xsl:template>

    <!-- Copie les formats inconnus des entrées / descriptions / résultats des opérations. -->
    <!-- TODO Aucun exemple, donc à vérifier. -->
    <xsl:template match="refNum:entree/* | refNum:description/* | refNum:resultat/* | refNum:commentaire/*"
        mode="children">
        <premis:eventOutcomeInformation>
            <premis:eventOutcome>
                <xsl:value-of select="$codes/operationTypeCommentaire
                    /entry[@code = current()/parent::refNum:*/@type]
                    /@premis" />
            </premis:eventOutcome>
            <premis:eventOutcomeDetail>
                <premis:eventOutcomeDetailExtension>
                    <xsl:apply-templates select="." mode="copy-namespace" />
                </premis:eventOutcomeDetailExtension>
            </premis:eventOutcomeDetail>
        </premis:eventOutcomeInformation>
    </xsl:template>

    <xsl:template match="detailsOperation:detailsOperation">
        <premis:eventOutcomeInformation>
            <premis:eventOutcome>
                <xsl:value-of select="$codes/operationTypeCommentaire
                    /entry[@code = current()/parent::refNum:*/@type]
                    /@premis" />
            </premis:eventOutcome>
            <premis:eventOutcomeDetail>
                <premis:eventOutcomeDetailExtension>
                    <xsl:apply-templates select="." mode="copy-prefix">
                        <xsl:with-param name="prefix" select="'detailsOperation'" />
                    </xsl:apply-templates>
                </premis:eventOutcomeDetailExtension>
            </premis:eventOutcomeDetail>
        </premis:eventOutcomeInformation>
    </xsl:template>

    <xsl:template match="refNum:vueObjet/refNum:*[name() = 'texte' or name() = 'image' or name() = 'audio']"
        mode="digiprovMD_valid">
        <xsl:param name="objetAssocie" select="'master'" />

        <xsl:variable name="numeroFichier" select="position()" />
        <xsl:variable name="numeroId" select="r2m:genereIndexAmd('digiprovMD_valide', $numeroFichier, $objetAssocie)" />

        <xsl:variable name="fileIdPart" select="r2m:fileIdPart($objetAssocie)" />
        <xsl:variable name="mimetype" select="r2m:mimetypeFichier(upper-case(@typeFichier), $objetAssocie)" />

        <xsl:element name="digiprovMD">
            <xsl:attribute name="ID">
                <xsl:text>AMD.</xsl:text>
                <xsl:value-of select="$numeroId" />
            </xsl:attribute>

            <mdWrap MDTYPE="PREMIS:EVENT" MIMETYPE="text/xml">
                <xmlData>
                    <premis:event>
                        <xsl:call-template name="premisEventIdentifier">
                            <xsl:with-param name="partie" select="'digiprovMD_valide'" />
                            <xsl:with-param name="numeroId" select="$numeroId" />
                        </xsl:call-template>

                        <premis:eventType>
                            <xsl:text>fileProcessing</xsl:text>
                        </premis:eventType>
                        <!-- Le champ eventDateTime est requis, mais pas forcément présent dans le refNum. -->
                        <premis:eventDateTime>
                            <xsl:variable name="resultat" select="r2m:trouveDateValidation(., $objetAssocie)" />
                            <xsl:choose>
                                <xsl:when test="$resultat and false()">
                                    <xsl:value-of select="$resultat" />
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="current-dateTime()"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </premis:eventDateTime>
                        <premis:eventDetail>
                            <xsl:text>fileProcessing is valid</xsl:text>
                        </premis:eventDetail>
                        <xsl:choose>
                            <xsl:when test="$objetAssocie = '' or $objetAssocie = 'master'">
                                <premis:eventOutcomeInformation>
                                    <premis:eventOutcome>
                                        <xsl:text>Well-Formed and valid</xsl:text>
                                    </premis:eventOutcome>
                                </premis:eventOutcomeInformation>
                            </xsl:when>
                            <xsl:otherwise>
                                <premis:eventOutcomeInformation>
                                    <premis:eventOutcome>
                                        <xsl:text>Well-Formed</xsl:text>
                                    </premis:eventOutcome>
                                </premis:eventOutcomeInformation>
                                <premis:eventOutcomeInformation>
                                    <premis:eventOutcome>
                                        <xsl:text>Valid</xsl:text>
                                    </premis:eventOutcome>
                                </premis:eventOutcomeInformation>
                            </xsl:otherwise>
                        </xsl:choose>

                        <!-- TODO Utilisation des outils de l'exemple BnF. -->
                        <premis:linkingAgentIdentifier>
                            <premis:linkingAgentIdentifierType>identificationTool</premis:linkingAgentIdentifierType>
                            <premis:linkingAgentIdentifierValue>ark:/12148/br2d2cb</premis:linkingAgentIdentifierValue>
                            <premis:linkingAgentRole>performer</premis:linkingAgentRole>
                        </premis:linkingAgentIdentifier>
                        <premis:linkingAgentIdentifier>
                            <premis:linkingAgentIdentifierType>characterizationTool</premis:linkingAgentIdentifierType>
                            <premis:linkingAgentIdentifierValue>ark:/12148/br2d238m</premis:linkingAgentIdentifierValue>
                            <premis:linkingAgentRole>performer</premis:linkingAgentRole>
                        </premis:linkingAgentIdentifier>
                        <xsl:choose>
                            <xsl:when test="$objetAssocie = '' or $objetAssocie = 'master'">
                            </xsl:when>
                            <xsl:otherwise>
                                <premis:linkingAgentIdentifier>
                                    <premis:linkingAgentIdentifierType>validationTool</premis:linkingAgentIdentifierType>
                                    <premis:linkingAgentIdentifierValue>ark:/12148/br2d2598</premis:linkingAgentIdentifierValue>
                                    <premis:linkingAgentRole>performer</premis:linkingAgentRole>
                                </premis:linkingAgentIdentifier>
                            </xsl:otherwise>
                        </xsl:choose>
                    </premis:event>
                </xmlData>
            </mdWrap>
        </xsl:element>
    </xsl:template>

    <xsl:template match="/refNum:refNum" mode="FileSection">
        <xsl:element name="fileSec">
            <!-- Groupe principal des fichiers (texte, image ou audio, non mélangés). -->
            <!-- TODO Faut-il séparer par texte / image / audio ? -->
            <xsl:if test="refNum:document/refNum:structure/refNum:vueObjet/refNum:*[name() = 'texte' or name() = 'image' or name() = 'audio']">
                <xsl:apply-templates select="." mode="FileGroup">
                    <xsl:with-param name="objetAssocie" select="'master'" />
                </xsl:apply-templates>

                <!-- Fichiers des objets associés (dans la mesure où la doc est claire). -->
                <xsl:for-each select="refNum:document/refNum:production/refNum:objetAssocie">
                    <xsl:apply-templates select="ancestor::refNum:refNum" mode="FileGroup">
                        <xsl:with-param name="objetAssocie" select="." />
                    </xsl:apply-templates>
                </xsl:for-each>
            </xsl:if>
        </xsl:element>
    </xsl:template>

    <xsl:template match="/refNum:refNum" mode="FileGroup">
        <xsl:param name="objetAssocie" select="'master'" />

        <xsl:element name="fileGrp">
            <xsl:attribute name="ID">
                <xsl:text>GRP.</xsl:text>
                <xsl:value-of select="r2m:indexObjetAssocie($objetAssocie) + 1" />
            </xsl:attribute>
            <xsl:attribute name="USE">
                <xsl:value-of select="$codes/objetAssocie/entry[@code = $objetAssocie]/@use" />
            </xsl:attribute>
            <xsl:apply-templates select="refNum:document/refNum:structure/refNum:vueObjet/refNum:*[name() = 'texte' or name() = 'image' or name() = 'audio']" mode="fichier">
                <xsl:with-param name="objetAssocie" select="$objetAssocie" />
            </xsl:apply-templates>
        </xsl:element>
    </xsl:template>

    <xsl:template match="refNum:vueObjet/refNum:*[name() = 'texte' or name() = 'image' or name() = 'audio']"
        mode="fichier">
        <xsl:param name="objetAssocie" select="'master'" />

        <xsl:variable name="fileIdPart" select="r2m:fileIdPart($objetAssocie)" />
        <xsl:variable name="numeroFichier" select="r2m:numeroFichier(.)" />
        <xsl:variable name="mimetype" select="r2m:mimetypeFichier(upper-case(@typeFichier), $objetAssocie)" />
        <xsl:variable name="href" select="r2m:adresseFichier(., $objetAssocie)" />

        <xsl:element name="file">
            <xsl:attribute name="ID">
                <xsl:value-of select="$fileIdPart" />
                <xsl:text>.</xsl:text>
                <xsl:value-of select="$numeroFichier" />
            </xsl:attribute>
            <xsl:if test="$mimetype != ''">
                <xsl:attribute name="MIMETYPE">
                    <xsl:value-of select="$mimetype" />
                </xsl:attribute>
            </xsl:if>
            <xsl:if test="last() > 1">
                <xsl:attribute name="SEQ">
                    <xsl:value-of select="$numeroFichier" />
                </xsl:attribute>
                <xsl:attribute name="GROUPID">
                    <xsl:value-of select="../@ordre" />
                </xsl:attribute>
            </xsl:if>

            <xsl:if test="$profil/section/AdministrativeMetadataSection/@remplir = 'true'">
                <xsl:variable name="amdIds">
                    <xsl:apply-templates select="." mode="amd_fichier">
                        <xsl:with-param name="objetAssocie" select="$objetAssocie" />
                    </xsl:apply-templates>
                </xsl:variable>
                <xsl:attribute name="ADMID">
                    <xsl:value-of select="normalize-space($amdIds)" />
                </xsl:attribute>
            </xsl:if>

            <xsl:if test="$parametres/fichiers/checksums/type">
                <xsl:variable name="checksumFichier" select="r2m:trouveChecksum($href)" />
                <xsl:if test="$checksumFichier != ''">
                    <xsl:attribute name="CHECKSUMTYPE">
                        <xsl:value-of select="$parametres/fichiers/checksums/type" />
                    </xsl:attribute>
                    <xsl:attribute name="CHECKSUM">
                        <xsl:value-of select="$checksumFichier" />
                    </xsl:attribute>
                </xsl:if>
            </xsl:if>

            <xsl:variable name="tailleFichier" select="r2m:trouveTaille($href)" />
            <xsl:if test="$tailleFichier != ''">
                <xsl:attribute name="SIZE">
                    <xsl:value-of select="$tailleFichier" />
                </xsl:attribute>
            </xsl:if>

            <xsl:element name="FLocat">
                <xsl:attribute name="LOCTYPE">
                    <xsl:value-of select="$adresse/loctype" />
                </xsl:attribute>
                <xsl:if test="$adresse/loctype = 'OTHER'">
                    <xsl:attribute name="OTHERLOCTYPE">
                        <xsl:value-of select="$adresse/otherloctype" />
                    </xsl:attribute>
                </xsl:if>
                <xsl:if test="$adresse/xlinkType != ''">
                    <xsl:attribute name="xlink:type">
                        <xsl:value-of select="$adresse/xlinkType" />
                    </xsl:attribute>
                </xsl:if>
                <xsl:attribute name="xlink:href">
                    <xsl:value-of select="$href" />
                </xsl:attribute>
            </xsl:element>

        </xsl:element>
    </xsl:template>

    <xsl:template match="refNum:vueObjet/refNum:*[name() = 'texte' or name() = 'image' or name() = 'audio']"
        mode="amd_fichier">
        <xsl:param name="objetAssocie" select="'master'" />

        <xsl:variable name="numeroFichier" select="r2m:numeroFichier(.)" />

        <xsl:if test="$profil/section/AdministrativeMetadataSection/sourceMD/@remplir = 'true'
            and ($objetAssocie = '' or $objetAssocie = 'master')
            ">
            <xsl:text>AMD.</xsl:text>
            <xsl:value-of select="r2m:genereIndexAmd('sourceMD', $numeroFichier, $objetAssocie)" />
        </xsl:if>

        <xsl:if test="$profil/section/AdministrativeMetadataSection/spar/@remplir = 'true'">
            <xsl:text> AMD.</xsl:text>
            <xsl:value-of select="r2m:genereIndexAmd('spar_objets', $numeroFichier, $objetAssocie)" />
        </xsl:if>

        <xsl:if test="$profil/section/AdministrativeMetadataSection/techMD/@remplir = 'true'
            and $profil/section/AdministrativeMetadataSection/techMD/meta/@remplir = 'true'">
            <xsl:text> AMD.</xsl:text>
            <xsl:value-of select="r2m:genereIndexAmd('techMD_meta', $numeroFichier, $objetAssocie)" />
        </xsl:if>

        <xsl:if test="$profil/section/AdministrativeMetadataSection/techMD/@remplir = 'true'
            and $profil/section/AdministrativeMetadataSection/techMD/info/@remplir = 'true'">
            <xsl:text> AMD.</xsl:text>
            <xsl:value-of select="r2m:genereIndexAmd('techMD_info', $numeroFichier, $objetAssocie)" />
        </xsl:if>

        <xsl:if test="$profil/section/AdministrativeMetadataSection/digiprovMD/@remplir = 'true'
        and $profil/section/AdministrativeMetadataSection/digiprovMD/valide/@remplir = 'true'">
            <xsl:text> AMD.</xsl:text>
            <xsl:value-of select="r2m:genereIndexAmd('digiprovMD_valide', $numeroFichier, $objetAssocie)" />
        </xsl:if>

        <!-- Les index de rightsMD sont plutôt au niveau de la carte physique (group). -->
        <!-- Les index de digiprovMD sont au niveau de la carte physique (group). -->
    </xsl:template>

    <xsl:template match="/refNum:refNum" mode="StructuralMap">
        <xsl:element name="structMap">
            <xsl:attribute name="TYPE">physical</xsl:attribute>

            <xsl:choose>
                <xsl:when test="$parametres/structure_types[@nom = $structure_types]/niveau_0/text() != ''">
                    <xsl:element name="div">
                        <xsl:attribute name="TYPE">
                            <xsl:value-of select="$parametres/structure_types[@nom = $structure_types]/niveau_0/text()" />
                        </xsl:attribute>
                        <xsl:attribute name="ID">
                            <xsl:text>DIV.</xsl:text>
                            <xsl:value-of select="1" />
                        </xsl:attribute>
                        <xsl:if test="$profil/section/DescriptiveMetadataSection/@remplir = 'true'
                            and $parametres/periodique/@remplir = 'true'">
                            <xsl:attribute name="DMDID">DMD.1</xsl:attribute>
                        </xsl:if>
                        <xsl:apply-templates select="." mode="StructuralMap_niveau_1" />
                    </xsl:element>
                </xsl:when>

                <xsl:otherwise>
                    <xsl:apply-templates select="." mode="StructuralMap_niveau_1" />
                </xsl:otherwise>
            </xsl:choose>

        </xsl:element>
    </xsl:template>

    <xsl:template match="/refNum:refNum" mode="StructuralMap_niveau_1">
        <xsl:choose>
            <xsl:when test="$parametres/structure_types[@nom = $structure_types]/niveau_1/text() != ''">
                <xsl:element name="div">
                    <xsl:attribute name="TYPE">
                        <xsl:value-of select="$parametres/structure_types[@nom = $structure_types]/niveau_1/text()" />
                    </xsl:attribute>
                    <xsl:variable name="genre" select="normalize-space(refNum:document/refNum:bibliographie/refNum:genre)" />
                    <xsl:choose>
                        <xsl:when test="$codes/genre/entry[@code = upper-case($genre)]">
                            <xsl:attribute name="LABEL">
                                <xsl:value-of select="$codes/genre/entry[@code = upper-case($genre)]" />
                            </xsl:attribute>
                        </xsl:when>
                        <xsl:when test="$parametres/section/StructuralMap/labelPhysicalGroup != ''">
                            <xsl:attribute name="LABEL">
                                <xsl:value-of select="$parametres/section/StructuralMap/labelPhysicalGroup" />
                            </xsl:attribute>
                        </xsl:when>
                    </xsl:choose>
                    <xsl:attribute name="ID">
                        <xsl:text>DIV.</xsl:text>
                        <xsl:value-of select="2" />
                    </xsl:attribute>
                    <xsl:if test="$profil/section/DescriptiveMetadataSection/@remplir = 'true'">
                        <!-- Contrairement à l'exemple de la BnF, le refNum ne renvoie pas
                        à une autre notice, donc le "set" et le "group" renvoient au même dmd. -->
                        <xsl:attribute name="DMDID">
                            <xsl:text>DMD.</xsl:text>
                            <xsl:value-of select="1 + number($parametres/periodique/@remplir = 'true')" />
                        </xsl:attribute>
                    </xsl:if>
                    <xsl:if test="$profil/section/AdministrativeMetadataSection/@remplir = 'true'">
                            <!-- Pas l'id du sourceMD, il est lié aux fichiers dans fileSec. -->
                            <!-- Pas l'id des techMD, ils sont liés aux fichiers dans fileSec. -->
                            <!-- TODO Ajouter les index de rightsMD (interdit pour Mets BnF). -->
                        <xsl:variable name="amdIds">
                            <xsl:apply-templates select="." mode="amd_document" />
                        </xsl:variable>
                        <xsl:if test="$amdIds != ''">
                            <xsl:attribute name="ADMID">
                                <xsl:value-of select="normalize-space($amdIds)" />
                            </xsl:attribute>
                        </xsl:if>
                    </xsl:if>

                    <xsl:apply-templates select="refNum:document/refNum:structure/refNum:vueObjet" mode="StructuralMap" />

                </xsl:element>
            </xsl:when>

            <xsl:otherwise>
                <xsl:apply-templates select="refNum:document/refNum:structure/refNum:vueObjet" mode="StructuralMap" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="/refNum:refNum" mode="amd_document">
        <xsl:if test="($nombreOperations > 0) and $profil/section/AdministrativeMetadataSection/digiprovMD/@remplir = 'true'">
            <xsl:for-each select="1 to $nombreOperations">
                <xsl:text> AMD.</xsl:text>
                <xsl:value-of select="r2m:genereIndexAmd('digiprovMD', ., '')" />
            </xsl:for-each>
        </xsl:if>

        <xsl:if test="$profil/section/AdministrativeMetadataSection/spar/@remplir = 'true'">
            <xsl:text> AMD.</xsl:text>
            <xsl:value-of select="r2m:genereIndexAmd('spar_creation', 0, '')" />
            <xsl:text> AMD.</xsl:text>
            <xsl:value-of select="r2m:genereIndexAmd('spar_preingest', 0, '')" />
            <xsl:text> AMD.</xsl:text>
            <xsl:value-of select="r2m:genereIndexAmd('spar_techMD', 0, '')" />

            <xsl:variable name="maxSparFin" select="$profil/section/AdministrativeMetadataSection/spar/@fin + number($parametres/periodique/@remplir = 'true')" />
            <xsl:for-each select="1 to xs:integer($maxSparFin)">
                <xsl:text> AMD.</xsl:text>
                <xsl:value-of select="r2m:genereIndexAmd('spar_fin', ., '')" />
            </xsl:for-each>
        </xsl:if>
    </xsl:template>

    <xsl:template match="refNum:vueObjet" mode="StructuralMap">
        <xsl:element name="div">
            <xsl:attribute name="TYPE">
                <xsl:value-of select="$parametres/structure_types[@nom = $structure_types]/niveau_objet/text()" />
            </xsl:attribute>
            <xsl:attribute name="ORDER">
                <xsl:value-of select="@ordre" />
            </xsl:attribute>

            <xsl:variable name="orderLabel"
                select="r2m:nomImage(., $profil/section/StructuralMap/orderLabel)" />
            <xsl:variable name="label"
                select="r2m:nomImage(., $profil/section/StructuralMap/label)" />

            <xsl:if test="$profil/section/StructuralMap/orderLabel/@remplir = 'true'">
                <xsl:attribute name="ORDERLABEL">
                    <xsl:value-of select="$orderLabel" />
                </xsl:attribute>
            </xsl:if>
            <xsl:if test="$profil/section/StructuralMap/label/@remplir = 'true'
                    and $label != ''
                    and (
                        $profil/section/StructuralMap/label/@remplir != 'true'
                        or $label != $orderLabel
                    )">
                <xsl:attribute name="LABEL">
                    <xsl:value-of select="$label" />
                </xsl:attribute>
            </xsl:if>

            <xsl:attribute name="ID">
                <xsl:text>DIV.</xsl:text>
                <!-- Plus 2, car il y a le set et le group. -->
                <xsl:value-of select="position() + 2" />
            </xsl:attribute>
            <xsl:if test="$profil/section/DescriptiveMetadataSection_fichiers/@remplir = 'true'">
                <xsl:attribute name="DMDID">
                    <xsl:text>DMD.</xsl:text>
                    <xsl:value-of select="r2m:genereIndexDmd(position())" />
                </xsl:attribute>
            </xsl:if>
            <xsl:if test="$profil/section/AdministrativeMetadataSection/@remplir = 'true'
                and .//refNum:commentaire">
                <xsl:variable name="resultat">
                    <xsl:apply-templates select="." mode="amd_objet" />
                </xsl:variable>
                <xsl:if test="$resultat != ''">
                    <xsl:attribute name="ADMID">
                        <xsl:value-of select="normalize-space($resultat)" />
                    </xsl:attribute>
                </xsl:if>
            </xsl:if>

            <xsl:for-each select="refNum:*[name() = 'texte' or name() = 'image' or name() = 'audio']">
                <xsl:variable name="numeroFichier" select="r2m:numeroFichier(.)" />
                <xsl:element name="fptr">
                    <xsl:attribute name="FILEID">
                        <xsl:value-of select="r2m:fileIdPart('master')" />
                        <xsl:text>.</xsl:text>
                        <xsl:value-of select="$numeroFichier" />
                    </xsl:attribute>
                </xsl:element>
                <xsl:for-each select="../../../refNum:production/refNum:objetAssocie">
                    <xsl:element name="fptr">
                        <xsl:attribute name="FILEID">
                            <xsl:value-of select="r2m:fileIdPart(.)" />
                            <xsl:text>.</xsl:text>
                            <xsl:value-of select="$numeroFichier" />
                        </xsl:attribute>
                    </xsl:element>
                </xsl:for-each>
            </xsl:for-each>

        </xsl:element>
    </xsl:template>

    <xsl:template match="refNum:vueObjet" mode="amd_objet">
        <xsl:variable name="base" select="count(preceding::refNum:commentaire)" />
        <xsl:for-each select=".//refNum:commentaire">
            <xsl:text> AMD.</xsl:text>
            <xsl:value-of select="$base + r2m:genereIndexAmd('digiprovMD_structure', position(), '')" />
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="remplir_StructuralLinks">
    </xsl:template>

    <xsl:template name="remplir_Behavior">
    </xsl:template>

    <!-- Templates spéciaux -->

    <!-- Renvoie le Premis eventIdentifier d'un élément pour une partie. -->
    <xsl:template name="premisEventIdentifier">
        <xsl:param name="partie" select="''" />
        <!-- Ce numéro est déjà toujours unique. -->
        <xsl:param name="numeroId" select="0" />

        <premis:eventIdentifier>
            <xsl:variable name="eventIdentifierFormat" select="$profil/section/AdministrativeMetadataSection/digiprovMD
                /eventIdentifierFormat[@utiliser = 'true'][1]/@nom" />
            <xsl:choose>
                <xsl:when test="$eventIdentifierFormat = 'uuid'">
                    <premis:eventIdentifierType>UUID</premis:eventIdentifierType>
                    <premis:eventIdentifierValue>
                        <xsl:value-of select="r2m:genereUUID(., $numeroId)" />
                    </premis:eventIdentifierValue>
                </xsl:when>
                <!-- Par défaut. -->
                <xsl:otherwise>
                    <premis:eventIdentifierType>ID Index</premis:eventIdentifierType>
                    <premis:eventIdentifierValue>
                        <xsl:value-of select="/refNum:refNum/refNum:document/@identifiant" />
                        <xsl:value-of select="$profil/section/AdministrativeMetadataSection/digiprovMD
                            /eventIdentifierFormat[@utiliser = 'true'][1]/@separateur" />
                        <xsl:value-of select="$numeroId" />
                    </premis:eventIdentifierValue>
                </xsl:otherwise>
            </xsl:choose>
        </premis:eventIdentifier>
    </xsl:template>

    <!-- Renvoie un ensemble de paires type / valeur séparés par des virgules pour la tomaison. -->
    <xsl:template match="/refNum:refNum/refNum:document/refNum:bibliographie/refNum:tomaison">
        <xsl:param name="egaleur" select="' '" />
        <xsl:param name="separateur" select="', '" />

        <xsl:value-of select="normalize-space(refNum:type)" />
        <xsl:value-of select="$egaleur" />
        <xsl:value-of select="normalize-space(refNum:valeur)" />
        <xsl:if test="position() != last()">
            <xsl:value-of select="$separateur" />
        </xsl:if>
    </xsl:template>

    <!-- ==============================================================
    OUTILS
    =============================================================== -->

    <!-- Retourne un sous-arbre en gérant correctement les préfixes et espaces de nom.
    Ce modèle remplace un copy-of qui enlève le préfixe et ajoute un espace de nom
    vide, notamment lorsque la source a fusionné les espaces de nom.
    Comme c'est un modèle récursif, il doit être utilisé uniquement pour les petits
    arbres. -->
    <xsl:template match="*" mode="copy-prefix">
        <xsl:param name="prefix" select="''" />
        <xsl:element name="{
            if ($prefix != '')
            then concat($prefix, ':', local-name())
            else local-name()
            }">
            <xsl:copy-of select="@*" />
            <xsl:value-of select="text()" />
            <xsl:apply-templates select="child::*" mode="copy-prefix">
                <xsl:with-param name="prefix" select="$prefix" />
            </xsl:apply-templates>
        </xsl:element>
    </xsl:template>

    <!-- Retourne un sous-arbre en gérant correctement les préfixes et espaces de nom.
    Ce modèle remplace un copy-of qui enlève le préfixe et ajoute un espace de nom
    vide, notamment lorsque la source a fusionné les espaces de nom.
    Comme c'est un modèle récursif, il doit être utilisé uniquement pour les petits
    arbres.
    Idem que copy-prefix, sauf qu'ici, le préfixe n'est pas connu, donc on utilise
    l'espace de nom. -->
    <!-- TODO Fusionner copy-prefix et copy-namespace en ajoutant toujours un préfixe. -->
    <xsl:template match="*" mode="copy-namespace">
        <xsl:variable name="namespace" select="namespace-uri()" />
        <xsl:element name="{local-name()}" namespace="{$namespace}">
            <xsl:copy-of select="@*" />
            <xsl:value-of select="text()" />
            <xsl:apply-templates select="child::*" mode="copy-namespace" />
        </xsl:element>
    </xsl:template>

    <xsl:template name="ajout_metadonnees">
        <xsl:param name="element" select="''" />

        <xsl:variable name="namespace" select="substring-before($element, ':')" />
        <xsl:variable name="elementName" select="substring-after($element, ':')" />

        <xsl:for-each select="$parametres//elementsCommuns/*[name() = $namespace]/*[name() = $elementName]">
            <xsl:if test=". != ''">
                <xsl:element name="{$element}">
                    <xsl:value-of select="." />
                </xsl:element>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>

</xsl:stylesheet>


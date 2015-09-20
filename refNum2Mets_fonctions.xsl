<?xml version="1.0" encoding="UTF-8"?>
<!--
Description : Convertit un fichier refNum en Mets.
Version : 20150921
Auteur : Daniel Berthereau pour l'École des Mines de Paris [http://bib.mines-paristech.fr]

Cette feuille dépend de refNum2Mets.xsl.
Elle contient des fonctions générales.

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

    xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:xlink="http://www.w3.org/1999/xlink"
    xmlns:dcterms="http://purl.org/dc/terms/"

    xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0"
    xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0"
    xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0"

    exclude-result-prefixes="
        xsl fn xs r2m refNum detailsOperation
        office text table
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

    <!-- Fichiers additionnels : utilise ceux présents à côté du fichier refNum,
    sinon ceux du présent dossier. -->
    <xsl:variable name="dirname" as="xs:string" select="
            string-join(tokenize(document-uri(/), '/')[position() &lt; last()], '/')" />
    <xsl:variable name="notices" as="xs:string"
        select="r2m:cheminFichier($parametres/documents/metadata/liste)" />
    <xsl:variable name="arks" as="xs:string"
        select="r2m:cheminFichier($parametres/documents/ark/liste)" />
    <xsl:variable name="fichier_metadata" as="xs:string"
        select="r2m:cheminFichier($parametres/fichiers/metadata/liste)" />
    <xsl:variable name="fichier_checksums" as="xs:string"
        select="r2m:cheminFichier($parametres/fichiers/checksums/liste)" />
    <xsl:variable name="fichier_tailles" as="xs:string"
        select="r2m:cheminFichier($parametres/fichiers/tailles/liste)" />

    <xsl:variable name="separateur" select="replace(
            $parametres/separateur,
            '(\.|\[|\]|\\|\||\-|\^|\$|\?|\*|\+|\{|\}|\(|\))',
            '\\$1')
            "/>

    <!-- ==============================================================
    Fonctions générales
    =============================================================== -->

    <!-- Vérifie si un fichier existe (le nom n'est pas vide). -->
    <xsl:function name="r2m:existeFichier" as="xs:boolean">
        <xsl:param name="fichier" />

        <xsl:choose>
            <xsl:when test="$fichier = 'notices'">
                <xsl:value-of select="if ($notices) then true() else false()" />
            </xsl:when>
            <xsl:when test="$fichier = 'arks'">
                <xsl:value-of select="if ($arks) then true() else false()" />
            </xsl:when>
            <xsl:when test="$fichier = 'fichier_metadata'">
                <xsl:value-of select="if ($fichier_metadata) then true() else false()" />
            </xsl:when>
            <xsl:when test="$fichier = 'fichier_checksums'">
                <xsl:value-of select="if ($fichier_metadata) then true() else false()" />
            </xsl:when>
            <xsl:when test="$fichier = 'fichier_tailles'">
                <xsl:value-of select="if ($fichier_metadata) then true() else false()" />
            </xsl:when>
        </xsl:choose>
    </xsl:function>

    <!-- Détermine le nom complet d'un fichier de données, qui peut être dans le
    dossier des sources ou dans le dossier des documents. -->
    <xsl:function name="r2m:cheminFichier" as="xs:string">
        <xsl:param name="nomFichier" />

        <xsl:choose>
            <xsl:when test="function-available('unparsed-text-available')">
                <xsl:value-of select="
                    if ($nomFichier/@chemin = 'xml')
                        then if (unparsed-text-available(concat($dirname, '/', $nomFichier), 'UTF-8'))
                            then concat($dirname, '/', $nomFichier)
                            else if (unparsed-text-available(resolve-uri($nomFichier)))
                                then resolve-uri($nomFichier)
                                else ''
                    else if (unparsed-text-available(resolve-uri($nomFichier)))
                        then resolve-uri($nomFichier)
                        else if (unparsed-text-available(concat($dirname, '/', $nomFichier), 'UTF-8'))
                            then concat($dirname, '/', $nomFichier)
                            else ''
                    " />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="
                        if ($nomFichier/@chemin = 'xml')
                        then concat($dirname, '/', $nomFichier)
                        else resolve-uri($nomFichier)
                        " />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!-- Extrait une valeur d'un fichier (la valeur est en première colonne, la clé ensuite). -->
    <xsl:function name="r2m:extraitValeur" as="xs:string?">
        <xsl:param name="fichier" />
        <xsl:param name="nom" />

        <!-- TODO Optimiser si besoin. -->
        <xsl:variable name="resultat">
            <xsl:for-each select="tokenize(unparsed-text($fichier, 'UTF-8'), '\r?\n')">
                <xsl:if test="normalize-space(substring-after(., ' ')) = $nom">
                    <xsl:value-of select="normalize-space(substring-before(., ' '))" />
                </xsl:if>
            </xsl:for-each>
        </xsl:variable>
        <xsl:value-of select="string($resultat)" />
    </xsl:function>

    <!-- Récupère une ligne de cellules d'un tableur OpenDocument. -->
    <!-- L'identifiant doit être dans la première colonne. -->
    <xsl:function name="r2m:extraitCellules">
        <xsl:param name="tableur" as="xs:string" />
        <xsl:param name="identifiant" as="xs:string" />

        <!-- TODO Optimiser si besoin. -->
        <xsl:variable name="row" select="document($tableur)
                /office:document-content/office:body/office:spreadsheet/table:table[1]
                /table:table-row[table:table-cell[1]/text:p = $identifiant]" />

        <xsl:if test="not(empty($row))">
            <!-- D'abord, reconstruire la liste des cellules pour gérer les cellules
            identiques ou vides. -->
            <xsl:variable name="row_simple">
                <xsl:for-each select="$row/table:table-cell">
                    <xsl:choose>
                        <xsl:when test="@table:number-columns-repeated">
                            <xsl:variable name="current_cell" select="." />
                            <xsl:for-each select="1 to  @table:number-columns-repeated">
                                <xsl:sequence select="$current_cell" />
                            </xsl:for-each>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:sequence select="." />
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>
            </xsl:variable>

            <!-- Ensuite, lier les cellules au nom des colonnes (qui doivent être du Dublin Core). -->
            <xsl:variable name="cellules">
                <xsl:for-each select="document($tableur)
                        /office:document-content/office:body/office:spreadsheet/table:table[1]
                        /table:table-row[1]/table:table-cell
                        ">
                    <!-- La première cellule est le nom du fichier, inutile désormais. -->
                    <xsl:if test="position() != 1">
                        <xsl:variable name="position" select="position()" />

                        <!-- Ne crée la métadonnée que s'il y a un contenu. -->
                        <xsl:if test="normalize-space($row_simple/table:table-cell[$position]) != ''">
                            <xsl:variable name="name" select="
                                if (starts-with(text:p[1], 'dc:'))
                                then text:p[1]
                                else if (starts-with(text:p[1], 'Dublin Core'))
                                    then concat('dc:', lower-case(normalize-space(substring-after(text:p[1], ':'))))
                                    else concat('dc:', lower-case(normalize-space(text:p[1])))
                                " />

                            <!-- Prise en compte les cellules multivaluées s'il y a un séparateur. -->
                            <xsl:choose>
                                <!-- Le séparateur est le saut de ligne interne à une cellule. -->
                                <xsl:when test="$separateur = 'EOL'">
                                    <xsl:for-each select="$row_simple/table:table-cell[$position]/text:p">
                                        <!-- Évite de créer un contenu pour un double saut. -->
                                        <xsl:if test="normalize-space(.)">
                                            <xsl:element name="{$name}">
                                                <!-- Nettoie le résultat (trim). -->
                                                <xsl:sequence select="replace(., '^\s*(.+?)\s*$', '$1')" />
                                            </xsl:element>
                                        </xsl:if>
                                    </xsl:for-each>
                                </xsl:when>

                                <!-- Autre séparateur ou pas de séparateur. -->
                                <xsl:otherwise>
                                    <xsl:variable name="contenu"
                                        select="string-join($row_simple/table:table-cell[$position]/text:p/text(), '')" />
                                    <xsl:choose>
                                        <xsl:when test="$separateur != '' and contains(string($contenu), $parametres/separateur)">
                                            <xsl:for-each select="tokenize(string($contenu), $separateur)">
                                                <!-- Évite de créer un contenu pour un séparateur oublié. -->
                                                <xsl:if test="normalize-space(.)">
                                                    <xsl:element name="{$name}">
                                                        <!-- Nettoie le résultat (trim). -->
                                                        <xsl:sequence select="replace(., '^\s*(.+?)\s*$', '$1')" />
                                                    </xsl:element>
                                                </xsl:if>
                                            </xsl:for-each>
                                        </xsl:when>

                                        <!-- Pas de séparateur. -->
                                        <xsl:otherwise>
                                            <xsl:element name="{$name}">
                                                <xsl:sequence select="$contenu" />
                                            </xsl:element>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:otherwise>
                            </xsl:choose>
                       </xsl:if>
                    </xsl:if>
                </xsl:for-each>
            </xsl:variable>

            <xsl:sequence select="$cellules" />
        </xsl:if>
    </xsl:function>

    <!-- Récupère la notice d'un document. -->
    <xsl:function name="r2m:trouveNotice">
        <!-- Identifiant du document refnum -->
        <xsl:param name="identifiant" />

        <xsl:sequence select="r2m:extraitCellules($notices, $identifiant)" />
    </xsl:function>

    <!-- Récupère les métadonnées d'un fichier. -->
    <xsl:function name="r2m:trouveMetadata">
        <!-- Adresse du fichier texte / image / audio. -->
        <xsl:param name="fichier" />

        <xsl:sequence select="r2m:extraitCellules($fichier_metadata, $fichier)" />
    </xsl:function>

    <!-- Récupère l'identifiant ark à partir de l'identifiant du document. -->
    <xsl:function name="r2m:trouveArk" as="xs:string?">
        <!-- Identifiant du document refnum -->
        <xsl:param name="identifiant" />

        <xsl:value-of select="r2m:extraitValeur($arks, $identifiant)" />
    </xsl:function>

    <!-- Récupère le hash d'un fichier. -->
    <xsl:function name="r2m:trouveChecksum" as="xs:string?">
        <!-- Adresse du fichier texte / image / audio. -->
        <xsl:param name="fichier" />

        <xsl:value-of select="r2m:extraitValeur($fichier_checksums, $fichier)" />
    </xsl:function>

    <!-- Récupère la taille d'un fichier. -->
    <xsl:function name="r2m:trouveTaille" as="xs:string?">
        <!-- Adresse du fichier texte / image / audio. -->
        <xsl:param name="fichier" />

        <xsl:value-of select="r2m:extraitValeur($fichier_tailles, $fichier)" />
    </xsl:function>

    <!-- L'uuid est créée à partir de l'heure et du generate-id (uuid version 1).
    Par définition, il est unique pour le traitement d'un fichier source, mais
    pas forcément sur plusieurs, quoique les collisions soient très peu probables,
    puisqu'il dépend aussi d'une date au millième de seconde.
    En tout état de cause, l'UUID est unique à l'intérieur de l'entrepôt tant que les
    scripts ne tournent pas en parallèle, ce qui est conforme à la norme Premis.
    -->
    <xsl:function name="r2m:genereUUID">
        <xsl:param name="element" />
        <xsl:param name="numeroId" />

        <!--  Pour "generate-id()", la première lettre est fixe, mais la longueur variable. -->
        <xsl:variable name="genId" select="substring(generate-id($element), 2)" />
        <!-- "generate-id" peut être un nombre, un hexa ou un alphanum. Comme
        cela dépend du processeur xsl, il ne faut pas laisser le choix. -->
        <xsl:variable name="decId" select="number(r2m:convertStringToNumsys($genId, 10))" />
        <!-- Position permet de régler le problème de gros id très proches. -->
        <xsl:variable name="position" select="count($element/preceding-sibling::*)" />
        <xsl:variable name="decEpoch" select="number(replace(string(current-dateTime() - xs:dateTime('1970-01-01T00:00:00')), '[^0-9]', ''))"/>
        <xsl:variable name="time" select="format-dateTime(current-dateTime(), '[f000001][s01][m01][h01][D01][M01][Y0001]')" />
        <xsl:variable name="decTime" select="number(replace($time, '[^0-9]', ''))" />
        <xsl:variable name="base" select="concat(
            r2m:convertDecToHex($numeroId),
            r2m:convertDecToHex($decId),
            r2m:convertDecToHex($position),
            r2m:convertDecToHex($decEpoch),
            r2m:convertDecToHex(replace(string($decId * $decTime), '\.', ''))
            )" />
        <!-- La chaîne produite fait toujours plus de 32 caractères (pas besoin
        de prolonger les sous-parties. -->
        <xsl:value-of select="lower-case(concat(
            substring($base, 1, 8), '-',
            substring($base, 9, 4), '-',
            substring($base, 13, 4), '-',
            substring($base, 17, 4), '-',
            substring($base, 21, 12)
            ))" />
    </xsl:function>

    <!-- Création d'une chaine de caractères en hexa à partir d'une chaîne.
    Basé sur http://lists.xml.org/archives/xml-dev/200109/msg00248.html -->
    <xsl:function name="r2m:convertStringToNumsys" as="xs:string" >
        <xsl:param name="string" as="xs:string" />
        <xsl:param name="base" as="xs:integer" />

        <xsl:variable name="alphanum" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ9876543210abcdefghijklmnopqrstuvwxyz'" />
        <xsl:variable name="hex" select="'0123456789abcdef'" />

        <xsl:variable name="clean-string" select="replace($string, '[^a-zA-Z0-9]', '')" />
        <xsl:if test="$clean-string">
            <xsl:variable name="first-char" select="substring($clean-string, 1, 1)" as="xs:string" />
            <xsl:variable name="pos-char" select="string-length(substring-before($alphanum, $first-char))" as="xs:integer" />
            <xsl:variable name="hex-digit1" select="substring($hex, floor($pos-char div $base) + 1, 1)" as="xs:string" />
            <xsl:variable name="hex-digit2" select="substring($hex, $pos-char mod $base + 1, 1)" as="xs:string" />
            <xsl:choose>
                <xsl:when test="string-length($clean-string) > 1">
                    <xsl:value-of select="concat($hex-digit1, $hex-digit2, r2m:convertStringToNumsys(substring($clean-string, 2), 10))" />
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat($hex-digit1, $hex-digit2)" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    </xsl:function>

    <xsl:function name="r2m:convertDecToHex">
        <xsl:param name="nombre" />
        <xsl:variable name="index" select="number($nombre)" />
        <xsl:if test="$index > 0">
            <xsl:variable name="v" select="r2m:convertDecToHex(floor(number($index) div 16))" />
            <xsl:variable name="w">
                <xsl:choose>
                    <xsl:when test="$index mod 16 &lt; 10">
                        <xsl:value-of select="$index mod 16" />
                    </xsl:when>
                    <xsl:when test="$index mod 16 = 10">A</xsl:when>
                    <xsl:when test="$index mod 16 = 11">B</xsl:when>
                    <xsl:when test="$index mod 16 = 12">C</xsl:when>
                    <xsl:when test="$index mod 16 = 13">D</xsl:when>
                    <xsl:when test="$index mod 16 = 14">E</xsl:when>
                    <xsl:when test="$index mod 16 = 15">F</xsl:when>
                    <xsl:otherwise>A</xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:value-of select="concat($v, $w)" />
        </xsl:if>
    </xsl:function>

    <!-- Convertit un nombre en hexadécimal. Le résultat n'est pas forcément
    correct (double), mais le but est d'avoir une chaîne suffisamment aléatoire.
    http://bytes.com/topic/net/answers/756726-xslt-2-0-format-number-binary-hex -->
    <xsl:function name="r2m:convertDecToNumsys" as="xs:string">
        <xsl:param name="dec" />
        <xsl:param name="base" as="xs:integer"/>

        <xsl:variable name="chr" as="xs:string" select="'0123456789abcdef'" />
        <xsl:variable name="car" select="$dec mod $base" />
        <xsl:variable name="cdr" select="$dec div $base" />

        <xsl:value-of select="concat(
                if ($base lt $dec) then r2m:convertDecToNumsys($cdr, $base) else '',
                substring($chr, 1 + $car, 1)
            )" />
    </xsl:function>

    <xsl:function name="r2m:getPrefixOfElement">
        <xsl:param name="element" />
        <xsl:variable name="namespaceUri" select="namespace-uri($element)" />
        <xsl:for-each select="in-scope-prefixes($element)">
            <xsl:if test="namespace-uri-for-prefix(., $element) = $namespaceUri">
                <xsl:value-of select="." />
            </xsl:if>
        </xsl:for-each>
    </xsl:function>

    <xsl:function name="r2m:numeroFixe" as="xs:string">
        <xsl:param name="numero" />
        <xsl:param name="longueur" />

        <xsl:variable name="chaine" select="concat('000000000', normalize-space(string($numero)))" />

        <xsl:value-of select="substring($chaine, string-length($chaine) - $longueur + 1)" />
    </xsl:function>

</xsl:stylesheet>


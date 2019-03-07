Duplicate Contact Removal:

Always Backup before attempting any of the sql query steps below!!!

    1. Make sure have c:\program files (x86)\labtech\backup\tablebase contacts.sql from the 3am backup current day - or make a dump of the table in case something goes bad.  I also copy out to excel sheet from sqlyog to use in case need to re-insert passwords/security for any contact deleted that had been setup with the LT Client Portal access.

    2. Delete FROM contacts WHERE externalID<>0 AND contactid NOT IN (SELECT contactid FROM computers) AND contactID NOT IN (SELECT contactid FROM alerttemplates) AND contactID NOT IN (SELECT contactid FROM locations) AND contactid NOT IN (SELECT contactid FROM reportscheduler)

    3. TRUNCATE plugin_cw_contactmapping

    4. INSERT INTO plugin_cw_contactmapping (
                    contactID,
                    CWContactRecID,
                    LastUpdate)
    SELECT ContactID,
                    ExternalID,
                    Last_Date
    FROM contacts

    5. DELETE FROM plugin_cw_contactmapping WHERE CWContactRecID=0

    6. Tools > Reload System Cache

    7. Then do the Import/Update and only select Import items



    ##### Darren version#####

##Update CWIgnoredEntities CWTargetRecID linked to Contacts with a different CWContactRecID
UPDATE
`plugin_cw_contactmapping` AS pcwc
JOIN `plugin_cw_ignoredentities` AS pcwi ON pcwi.targettype='13' AND pcwi.CWTargetRecID>=0 AND pcwi.lttargetid=pcwc.contactid AND pcwi.CWTargetRecID<>pcwc.CWContactRecID
SET pcwi.CWTargetRecID=pcwc.CWContactRecID
WHERE pcwc.CWContactRecID>0;

##Update CWContactMapping CWContactRecID linked to Contacts with a different ExternalID that are NOT in the cw_ignoredentities.
UPDATE
`plugin_cw_contactmapping` AS pcwc
JOIN contacts AS c1 ON c1.contactid=pcwc.contactid AND c1.externalid>0 AND c1.externalid<>pcwc.CWContactRecID
LEFT JOIN `plugin_cw_ignoredentities` AS pcwi ON pcwi.lttargetid=c1.contactid AND pcwi.targettype='13'
SET pcwc.CWContactRecID=c1.externalid
WHERE ISNULL(pcwi.LTTargetID);

##Cleanup completely identical contacts, lowest ID wins.
DELETE FROM c2 USING
#SELECT * FROM
contacts AS c1
JOIN contacts AS c2 USING (clientid,firstname,lastname,address1,address2,city,state,zip,phone,cell,fax,pager,email,emailpassword,msn,aim,icq,netbiosname,externalid,guid,PASSWORD,websecurity,pwsetflag,imageid,contactflags)
WHERE c1.contactid<c2.contactid AND c1.externalid>0;

##Cleanup multiple contacts assigned to the same external ID, "Best Configured" or most recently updated wins.
#DELETE FROM c2 USING
SELECT * FROM
contacts AS c1
JOIN contacts AS c2 USING (externalid)
WHERE c1.externalid>0
AND IF(c1.contactflags>c2.contactflags,1,IF(c1.contactflags=c2.contactflags,IF(c1.websecurity>c2.websecurity,1,IF(c1.websecurity=c2.websecurity,IF(c1.password>c2.password,1,IF(c1.password=c2.password,IF(c1.last_date>c2.last_date,1,0),0)),0)),0))=1;

##Find CWContacts where the Automate contactid does not exist.
#DELETE FROM pcwc USING
SELECT * FROM
`plugin_cw_contactmapping` AS pcwc
LEFT JOIN contacts AS c1 ON c1.contactid=pcwc.contactid
WHERE ISNULL(c1.contactid);

##Find CW IgnoredEntities where the contactid does not exist.
#DELETE FROM pcwi USING
SELECT * FROM
`plugin_cw_ignoredentities` AS pcwi
LEFT JOIN contacts AS c1 ON c1.contactid=pcwi.lttargetid
WHERE pcwi.targettype='13' AND ISNULL(c1.contactid);

##Remove contacts that are not used anywhere BUT are supposedly linked to an external contact ID, only for clients that are NOT linked to an external ID AND that are hidden.
#Since Automate 12 doesn't hide clients, this may not clean up much. (Contacts for deleted clients would be purged though...)
#DELETE FROM pcwi,pcwc,ct,efd USING
SELECT pcwi.*,pcwc.*, ct.*,efd.* FROM
contacts AS ct
LEFT JOIN clients AS cl ON cl.clientid=ct.clientid
LEFT JOIN locations AS loc ON loc.locationid=ct.locationid
LEFT JOIN extrafielddata AS efd ON efd.id=ct.contactid AND efd.extrafieldid IN (SELECT DISTINCT ID FROM extrafield WHERE form=13)
LEFT JOIN `plugin_cw_contactmapping` AS pcwc ON pcwc.contactid=ct.contactid
LEFT JOIN `plugin_cw_ignoredentities` AS pcwi ON pcwi.lttargetid=ct.contactid AND pcwi.targettype='13'
WHERE ct.contactid>2
AND ct.contactid NOT IN (SELECT DISTINCT contactid FROM contactcomputers)
AND ct.contactid NOT IN (SELECT DISTINCT contactid FROM contactpwtoken)
AND ct.contactid NOT IN (SELECT DISTINCT contactid FROM computers)
AND ct.contactid NOT IN (SELECT DISTINCT contactid FROM locations)
AND ct.contactid NOT IN (SELECT DISTINCT contactid FROM alerttemplates)
AND ct.contactid NOT IN (SELECT DISTINCT contactid FROM agents)
AND ( (IFNULL(cl.externalid,0)=0 AND ct.externalid>0)
AND (ct.clientid=1 OR cl.flags&6=6) );

SELECT v_extradatalocations.locationid,
      clients.name
      AS `Client`,
      v_extradatalocations.`name`
      AS `Location`,
      IF(locations.`passwordid` = 0, 'Not Selected', passwords.`title`)
      AS
      `Administrator Credentials`,
      IF(v_extradatalocations.`enable onboarding` = 1, 'Enabled', 'Disabled')
      AS
      `Onboarding`,
      v_extradatalocations.`workstation service plan`
      AS `Workstation Service Plan`,
      v_extradatalocations.`server service plan`
      AS `Server Service Plan`,
      v_extradatalocations.`workstations under contract`
      AS `Workstations Covered`,
      v_extradatalocations.`servers under contract`
      AS `Servers Covered`,
      v_extradatalocations.locationid
      AS `Hidden_LocationID`,
      clients.clientid
      AS `Hidden_ClientID`
FROM   (((v_extradatalocations
         LEFT JOIN locations
                ON v_extradatalocations.locationid = locations.locationid)
        LEFT JOIN clients
               ON locations.clientid = clients.clientid)
       LEFT JOIN passwords
              ON locations.passwordid = passwords.passwordid)
ORDER  BY IF(v_extradatalocations.`enable patching workstations` =
         1,
                   v_extradatalocations.`patch day workstations`, 'Disabled')
         DESC

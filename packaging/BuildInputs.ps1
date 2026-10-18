$ExpectedRgiMessages = @(
    [ordered]@{ Symbol = 'IAP2_MSG_ROUTE_GUIDANCE_START';    Id = '0x5200'; Direction = 'Sent' }
    [ordered]@{ Symbol = 'IAP2_MSG_ROUTE_GUIDANCE_UPDATE';   Id = '0x5201'; Direction = 'Received' }
    [ordered]@{ Symbol = 'IAP2_MSG_ROUTE_GUIDANCE_MANEUVER'; Id = '0x5202'; Direction = 'Received' }
    [ordered]@{ Symbol = 'IAP2_MSG_ROUTE_GUIDANCE_STOP';     Id = '0x5203'; Direction = 'Sent' }
    [ordered]@{ Symbol = 'IAP2_MSG_ROUTE_GUIDANCE_LANE';     Id = '0x5204'; Direction = 'Received' }
)

$RgiMessageIds = @($ExpectedRgiMessages | ForEach-Object { $_.Id })

$RgiSentIds =
    @($ExpectedRgiMessages | Where-Object { $_.Direction -eq 'Sent' } | ForEach-Object { $_.Id })

$RgiReceivedIds =
    @($ExpectedRgiMessages | Where-Object { $_.Direction -eq 'Received' } | ForEach-Object { $_.Id })

# Calls and car data (the app's HOOK_PHONE_DATA): registered only when the source builds
# them. Each ID is checked against the define in the hook module that handles it.
$ExpectedPhoneDataMessages = @(
    [ordered]@{ Symbol = 'MSG_ACCEPT_CALL';           Id = '0x415B'; Direction = 'Sent';     Source = 'hook/telephony/tel_hook.c' }
    [ordered]@{ Symbol = 'MSG_END_CALL';              Id = '0x415C'; Direction = 'Sent';     Source = 'hook/telephony/tel_hook.c' }
    [ordered]@{ Symbol = 'MSG_SWAP_CALLS';            Id = '0x415D'; Direction = 'Sent';     Source = 'hook/telephony/tel_hook.c' }
    [ordered]@{ Symbol = 'MSG_HOLD_STATUS_UPDATE';    Id = '0x415F'; Direction = 'Sent';     Source = 'hook/telephony/tel_hook.c' }
    [ordered]@{ Symbol = 'MSG_MUTE_STATUS_UPDATE';    Id = '0x4160'; Direction = 'Sent';     Source = 'hook/telephony/tel_hook.c' }
    [ordered]@{ Symbol = 'MSG_START_LIST_UPDATES';    Id = '0x4170'; Direction = 'Sent';     Source = 'hook/telephony/tel_hook.c' }
    [ordered]@{ Symbol = 'MSG_LIST_UPDATE';           Id = '0x4171'; Direction = 'Received'; Source = 'hook/telephony/tel_hook.c' }
    [ordered]@{ Symbol = 'MSG_START_VEHICLE_STATUS';  Id = '0xA100'; Direction = 'Received'; Source = 'hook/vehicle/vehicle_hook.c' }
    [ordered]@{ Symbol = 'MSG_VEHICLE_STATUS_UPDATE'; Id = '0xA101'; Direction = 'Sent';     Source = 'hook/vehicle/vehicle_hook.c' }
    [ordered]@{ Symbol = 'MSG_STOP_VEHICLE_STATUS';   Id = '0xA102'; Direction = 'Received'; Source = 'hook/vehicle/vehicle_hook.c' }
)

$PhoneDataSentIds =
    @($ExpectedPhoneDataMessages | Where-Object { $_.Direction -eq 'Sent' } | ForEach-Object { $_.Id })

$PhoneDataReceivedIds =
    @($ExpectedPhoneDataMessages | Where-Object { $_.Direction -eq 'Received' } | ForEach-Object { $_.Id })

# PASCD (VehicleSpeedData) ORed into iap2.nmea: the vehicle module supplies the
# wheel-speed sentences, so dio must advertise them.
$PhoneDataNmeaBits = 0x08

# Maven Central artifacts are immutable. Cross-checked against the published
# repo1.maven.org .sha1 files.
$OsgiFrameworkSha256 = 'E00700B2C07A68D6F70A7B42BD29D599BBE76BD11E96A34B61E4DE45A98AB1BE'
$OsgiTrackerSha256 = '7D78C2CC9BCB6421C24F17AA097866CE8D9115C219A4F8D6CC753BC4DFB97EFA'

# ASM runs only the host-side stock linkage audit; it is never packaged.
# Cross-checked against the published repo1.maven.org .sha1 files.
$AsmSha256 = 'ADF46D5E34940BDF148ECDD26A9EE8EEA94496A72034FF7141066B3EEA5C4E9D'
$AsmTreeSha256 = '62F4B3BC436045C1ACB5C3BA2D8EC556EC3369093D7F5D06C747EB04B56D52B1'

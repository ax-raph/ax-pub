<style>
  @import url("https://d3a2yuhvc71l40.cloudfront.net/lab.css");
     /* =========
       DEFAULT (NOT Resources tab):
       - Hide VM + resizer
       - Give guide 100% width
       ========= */
    .vm-environment .main-section:not(:has(#link_5 a.active-tab)):not(:has(#link_5-dup a.active-tab)) app-vm,
    .vm-environment .main-section:not(:has(#link_5 a.active-tab)):not(:has(#link_5-dup a.active-tab)) .resizer {
      display: none !important;
    }
    
    .vm-environment .main-section:not(:has(#link_5 a.active-tab)):not(:has(#link_5-dup a.active-tab)) #guideBlock {
      width: 100% !important;
      flex: 1 1 auto !important;
    }
    
    
    /* =========
       RESOURCES tab only:
       - Show VM on the RIGHT
       - Guide/controls on the LEFT
       - Keep the slider working
       ========= */
    
    /* Turn the main area into a flex row, but reverse visually so:
       Left = guideBlock, middle = resizer, right = VM
       (DOM order stays the same, so the resizer JS still works) */
    .vm-environment .main-section:has(#link_5 a.active-tab),
    .vm-environment .main-section:has(#link_5-dup a.active-tab) {
      display: flex !important;
      flex-direction: row-reverse !important;
      align-items: stretch !important;
    }
    
    /* Make sure VM + resizer are visible on Resources */
    .vm-environment .main-section:has(#link_5 a.active-tab) app-vm,
    .vm-environment .main-section:has(#link_5-dup a.active-tab) app-vm,
    .vm-environment .main-section:has(#link_5 a.active-tab) .resizer,
    .vm-environment .main-section:has(#link_5-dup a.active-tab) .resizer {
      display: block !important;
    }
    
    /* Let the VM take the remaining space (right side) */
    .vm-environment .main-section:has(#link_5 a.active-tab) app-vm,
    .vm-environment .main-section:has(#link_5-dup a.active-tab) app-vm {
      flex: 1 1 auto !important;
      min-width: 420px !important;
    }
    
    /* Keep guideBlock as the left "control pane".
       IMPORTANT: don't force a fixed width here — CloudLabs sets inline width
       (and the resizer updates it), so we only set sane min/max. */
    .vm-environment .main-section:has(#link_5 a.active-tab) #guideBlock,
    .vm-environment .main-section:has(#link_5-dup a.active-tab) #guideBlock {
      flex: 0 0 auto !important;
      min-width: 340px !important;
      max-width: 65vw !important;
    }
    
    /* Make the resizer easy to grab */
    .vm-environment .main-section:has(#link_5 a.active-tab) .resizer,
    .vm-environment .main-section:has(#link_5-dup a.active-tab) .resizer {
      flex: 0 0 10px !important;
      cursor: col-resize !important;
      z-index: 9999 !important;
    }
    
    /* ==========================
     Always show all top tabs (never collapse into "More")
     ========================== */
  
    /* Force main tabs to be visible even if CloudLabs set inline display:none */
    ul.resize-tab.ts-tabs-list > li[id^="link_"] {
      display: inline-block !important;
    }
    
    /* Hide the "More" dropdown container entirely */
    ul.dropdown-ul.ts-tabs-list,
    .custom-dropdown-tab,
    a.more-link,
    #myTabDrop1,
    #myTabDrop1-contents {
      display: none !important;
    }
    
    /* Allow horizontal scroll instead of collapsing */
    ul.resize-tab.ts-tabs-list {
      overflow-x: auto !important;
      white-space: nowrap !important;
      flex-wrap: nowrap !important;
    }

</style>


<div class="content-container">

# Exposures Implementation Guide

## Overview

<blockquote class="overview">
  In this lab, you will deploy and configure the Axonius Exposures, as we would during a customer PoV or Onboarding, to gain visibility into an organization's security vulnerabilities and risk posture. You'll work with dashboards, risk scoring, custom fields, and automation to create a comprehensive vulnerability management system.
</blockquote>

### What You'll Learn

* How and what to configure in adapters for Exposures data collection
* Create custom fields and Action Center automations
* Build and customize risk scores for devices
* Deploy and personalize Exposures dashboards
* Define critical assets and remediation ownership

### Important Note About Team Naming

<blockquote class="error">
  This is a shared lab environment with multiple groups. When naming resources, please follow the naming convention displayed to you. 
</blockquote>

<br>

---

<br>

## Exposure PoV Deployment Checklist

While in this lab some of the configurations are set for you, prior to PoV'ing Exposures, ensure the following have been completed: <br>
✓ Axonius version 8.0.14 or above is installed <br>
&nbsp;&nbsp;&nbsp;&nbsp;→ Significant improvements have been released in 8.0.14 that aid in performance and accuracy for Exposures <br>
✓ All devices have been fetched by adapters <br>
✓ Devices are in a good data hygiene state <br>
✓ All adapters that will be used for Exposures are identified <br>

<br>

## Task 1: Verify Adapter Configuration for Exposures

<blockquote class="overview">
  Before deploying Exposures, you need to ensure that your adapters are properly configured to collect vulnerability and security findings data. In this task, you'll review which adapters provide the necessary data types for Exposures.
</blockquote>

1. In the Axonius portal, navigate to **Adapters** in the left-side menu.

1. Click on **Search Asset Type...** to filter the adapter view. Select the following asset types:
   - **Network/Firewall Rules**
   - **Aggregated Security Findings**
   - **Security Findings**

    <br>

    <div>

     <img src="img/exposures_adapter_filter.png" style="width: 600px !important; border: #000 1px outset">

    </div>

    <br>

1. Review the list of configured adapters that provide these asset types.Take note of which adapters are bringing in vulnerability and security findings data. 

Typical adapters we work with on customer deployments include:

  - **Risk-Based Vulnerability Management (RBVM)**: Tenable, Qualys, Rapid7, Crowdstrike Spotlight
  - **Cloud Security Posture Management (CSPM)**: AWS Security Hub, Azure Security Center, Google Cloud Security Command Center
  - **Static/Dynamic Application Security Testing**: GitHub Advanced Security, SonarQube, Checkmarx
  - **Network Security**: Palo Alto Panorama, Cisco Firepower, Fortinet FortiGate
  - **Endpoint Detection & Response (EDR)**: CrowdStrike, SentinelOne, Microsoft Defender

<br>

---

<br>

## Task 2: Review Advanced Adapter Settings

<blockquote class="overview">
  Many adapters have advanced configuration options that enhance the data available for Exposures. In this task, you'll explore these settings to ensure you're collecting the most comprehensive vulnerability data.
</blockquote>

1. Find and select the **GitHub** adapter to view its configuration.

1. Click on **Advanced Configuration**.

1. Confirm that the setting **Fetch repository vulnerabilities** is enabled.

    <blockquote class="warning">
      For Exposures to work effectively, this setting must be enabled. Many security findings adapters have similar options that are disabled by default to reduce data volume, but they're critical for vulnerability visibility.
    </blockquote>

1. Back to the Adapters list, find and select the **Palo Alto Networks Panorama** adapter.

1. Click on **Advanced Configuration**.

1. Find the **Fetch network routes** setting. In an environment where Panorama is the primary firewall, this setting should be enabled.

    <blockquote class="warning">
      The Panorama adapter requires specific advanced settings to fetch firewall and load balancer rules. Check the <a href="https://axonius.atlassian.net/wiki/spaces/AG/pages/5699338270/Network+Routes" target="_blank">Confluence page on Network Routes</a> for a complete list of supported adapters and required configuration options.
    </blockquote>

<br>

---

<br>

## Task 3: Customize Base Queries for Your Environment

<blockquote class="overview">
  The Exposures templates include a base query that defines "active" devices. Since this is a shared lab environment, we will narrow down results to your VMs only.
</blockquote>

1. Navigate to **Queries** > **Public Queries** > <inject key="azureaduseremail" cloudname="Amazon Web Services" value=" Exposures" enableCopy="false" enableClickToPaste="false" style="color:#FF6112" /> > **Custom**.

1. Open the saved query: <inject key="azureaduseremail" cloudname="Amazon Web Services" value=" Active Devices (30d)" enableCopy="false" enableClickToPaste="false" style="color:#FF6112" />

1. Edit the query and replace `Freitas - My Stuff` with <inject key="azureaduseremail" cloudname="Amazon Web Services" value=" - My Assets" enableCopy="false" enableClickToPaste="false" style="color:#FF6112" /> 

1. Review the query logic to understand how "active" is defined.

    <blockquote class="note">
      In a production environment, you would customize this query based on your organization's definition of an "active" device. This might include specific last-seen timeframes, exclusions for certain device types, or integration with CMDB data.
    </blockquote>

<question source="https://docs-api.cloudlabs.ai/repos/raw.githubusercontent.com/Axonius/academy/refs/heads/main/gko2027/questions/_q1_active_devices.md" />

<br>

---

<br>

## Task 4: Create a Custom Field for Vulnerability Severity

<blockquote class="overview">
  To enable risk scoring based on vulnerability severity, you'll create a custom field that categorizes devices by their highest-severity vulnerability. This field will be automatically populated by Action Center enforcement sets in the next task.
</blockquote>

1. Navigate to **Settings** > **Data** > **Custom Data Management**.

1. Click on **+ Add Custom Field** at the top right.

1. Configure the custom field with the following settings:
   - **Field Name**: <inject key="azureaduseremail" cloudname="Amazon Web Services" value=" Exposures Device Risk Vulnerability Severity" enableCopy="false" enableClickToPaste="false" style="color:#FF6112" />
   - **Field Type**: Single Select
   - **Value Type**: String
   - **Asset Type**: Devices
   - **Dropdown**: (copy and paste the values below) <br>
   &nbsp;&nbsp;- Critical; High; Medium; Low; None; Other

    <br>

    <div>

     <img src="img/exposures_custom_field.png" style="width: 600px !important; border: #000 1px outset">

    </div>

    <br>

1. Click **Create Field**.

    <blockquote class="overview">
      To ensure the custom field appears quickly in the enforcement set, manually add data to it:
    </blockquote>

1. Navigate to **Assets** > **Compute** > **Devices**.

1. Search for one of your jumpbox servers and open the device.

1. Click **Add Custom Field**.

1. Select the custom field name: <inject key="azureaduseremail" cloudname="Amazon Web Services" value=" Exposures Device Risk Vulnerability Severity" enableCopy="false" enableClickToPaste="false" style="color:#FF6112" />

1. Set the **Value** to: **Other**

1. Click **Save**.

    <blockquote class="note">
      This custom field will be used by your risk scoring logic to quickly identify the most severe vulnerability on each device. The Action Center enforcement sets you create on Task 5 will automatically populate this field.
    </blockquote>

<br>

---

<br>

## Task 5: Import Exposures Dashboards

<blockquote class="overview">
  Axonius provides pre-built dashboard templates for Exposures that give you immediate visibility into your vulnerability landscape. In this task, you'll import these dashboards and customize them for your team.
</blockquote>

1. Copy the command below and execute it in your terminal to download the dashboard file (`dash.json`): _if you use Windows, open WSL/bash terminal or ask one of your teammates that has a Mac 😎_.

   <div style="width: 850px;">

    <inject value="curl -s https://raw.githubusercontent.com/Axonius/ax-docs-pub/refs/heads/main/academy/data.json | bash <(curl -s https://raw.githubusercontent.com/Axonius/ax-docs-pub/refs/heads/main/academy/dash.sh) -v &apos;" key="azureaduseremail" cloudname="Amazon Web Services" value="&apos; \\n> dash.json" enableCopy="false" enableClickToPaste="false" style="color:#FF6112" /> <br>

   </div>

1. In Axonius, navigate to **Dashboards**. Click on **Create Dashboard** > **Import**.

    <br>

    <div>

     <img src="img/importdash2.png" style="width: 400px !important; border: #000 1px outset">

    </div>

    <br>

1. Select the **dash.json** file. Then set `Who has access` = Public | `Folder` = Public.

1. Click **Save**.

1. When prompted about existing dashboards, choose **Overwrite**.

    <blockquote class="warning">
      Make sure you select "Overwrite" to ensure the dashboard templates are imported with all their configurations intact.
    </blockquote>

1. After the importing process is completed, you should see your three dashboards under the Public folder.
   - <inject key="azureaduseremail" cloudname="Amazon Web Services" value=" Exposures: Executive Dashboard" enableCopy="false" enableClickToPaste="false" style="color:#FF6112" />
   - <inject key="azureaduseremail" cloudname="Amazon Web Services" value=" Exposures: Remediation Owner" enableCopy="false" enableClickToPaste="false" style="color:#FF6112" />
   - <inject key="azureaduseremail" cloudname="Amazon Web Services" value=" Exposures: Implementation Help Charts" enableCopy="false" enableClickToPaste="false" style="color:#FF6112" />

   <br>

    <blockquote class="warning">
        There will a LOT of dashboards in this tenant, use the search bar to find yours. You can type the prefix odl_user_xxxxxxx and search.
    </blockquote>
  
    <div>

    <img src="img/exposures_dashboards_imported.png" style="width: 400px !important; border: #000 1px outset">

    </div>

    <br>

---

<br>

## Task 6: Create Action Center Enforcement Sets

<blockquote class="overview">
  Now you'll create a series of enforcement sets that automatically tag devices based on their vulnerability severity. These enforcement sets will populate the custom field you just created, enabling dynamic risk scoring.
</blockquote>

### Part 1: Create the Reset Enforcement Set

1. Navigate to **Action Center**.

1. Click **Create Enforcement Set** at the top right.

1. In the **Select Assets** tab:
   - Choose **Devices** as the asset type
   - Select the saved query: <inject key="azureaduseremail" cloudname="Amazon Web Services" value=" Devices with Vulnerability Visibility (30d)" enableCopy="false" enableClickToPaste="false" style="color:#FF6112" />

1. In the **Select Action** tab:
   - Search for "custom" in the action search bar
   - Select **Axonius - Remove Custom Data from Assets**

1. Configure the action:
   - **Field Name**: Select your <inject key="azureaduseremail" cloudname="Amazon Web Services" value=" Exposures Device Risk Vulnerability Severity" enableCopy="false" enableClickToPaste="false" style="color:#FF6112" /> custom field
   - **Action Condition**: Remove Entire Field

1. In the **Select Schedule** tab:
   - Set **Select Schedule Plan** to **On** -> **Every global discovery cycle**
   - Set **Ends** to **Never**

1. In the **Enforcement Set Name** tab:
   - Name: <inject key="azureaduseremail" cloudname="Amazon Web Services" value=" Device Risk Vulnerability Severity Custom Field Reset" enableCopy="false" enableClickToPaste="false" style="color:#FF6112" />

1. Click **Save and Run**.

1. After the enforcement set is created, click on the elipsis (right side) and select **Change Run Priority**.

   <div>

    <img src="img/ec_change_priority.png" style="width: 400px !important; border: #000 1px outset">

   </div>

1. Change the **Run Priority** to **3**.

    <blockquote class="note">
      The reset enforcement set runs first (priority 3) to clear all values, then the specific severity enforcement sets run afterward (priority 4+) to set the appropriate values. This ensures each device gets tagged with only its highest severity vulnerability.
    </blockquote>

<br>

### Part 2: Create the Critical Severity Enforcement Set

1. Click **Create Enforcement Set** again.

1. In the **Select Assets** tab:
   - Choose **Devices**
   - Select the saved query: <inject key="azureaduseremail" cloudname="Amazon Web Services" value=" Device Risk Open Critical Vulnerabilities (30d)" enableCopy="false" enableClickToPaste="false" style="color:#FF6112" />

1. In the **Select Action** tab:
   - Search for "custom" in the action search bar
   - Select **Axonius - Add Custom Data to Assets**

1. Configure the action:
   - **Field Name**: <inject key="azureaduseremail" cloudname="Amazon Web Services" value=" Exposures Device Risk Vulnerability Severity" enableCopy="false" enableClickToPaste="false" style="color:#FF6112" />
   - **Field Value**: `Critical`

1. In the **Select Schedule** tab:
   - Set **Select Schedule Plan** to **On** -> **Every global discovery cycle**
   - Set **Ends** to **Never**
   
1. In the **Enforcement Set Name** tab:
   - Name the enforcement set: <inject key="azureaduseremail" cloudname="Amazon Web Services" value=" Device Risk Vulnerability Severity Custom Field Critical" enableCopy="false" enableClickToPaste="false" style="color:#FF6112" />

1. Click **Save and Run**.

1. Change the **Run Priority** to **4**.

<br>

### Part 3: Create Remaining Severity Enforcement Sets

<blockquote class="overview">
  Instead of creating each enforcement set from scratch, you'll duplicate the Critical enforcement set and modify only the severity-specific settings. This saves time and ensures consistency across all enforcement sets.
</blockquote>

**For each severity level below, repeat these steps:**

1. In **Action Center**, locate your Critical enforcement set: <inject key="azureaduseremail" cloudname="Amazon Web Services" value=" Device Risk Vulnerability Severity Custom Field Critical" enableCopy="false" enableClickToPaste="false" style="color:#FF6112" />

1. Click the **three-dots menu (⋮)** next to the enforcement set.

1. Select **Duplicate**.

1. In the duplicate dialog, update the **Enforcement set name** to match the new severity level:
   - **High**: <inject key="azureaduseremail" cloudname="Amazon Web Services" value=" Device Risk Vulnerability Severity Custom Field High" enableCopy="false" enableClickToPaste="false" style="color:#FF6112" />
   - **Medium**: <inject key="azureaduseremail" cloudname="Amazon Web Services" value=" Device Risk Vulnerability Severity Custom Field Medium" enableCopy="false" enableClickToPaste="false" style="color:#FF6112" />
   - **Low**: <inject key="azureaduseremail" cloudname="Amazon Web Services" value=" Device Risk Vulnerability Severity Custom Field Low" enableCopy="false" enableClickToPaste="false" style="color:#FF6112" />
   - **Other**: <inject key="azureaduseremail" cloudname="Amazon Web Services" value=" Device Risk Vulnerability Severity Custom Field Other" enableCopy="false" enableClickToPaste="false" style="color:#FF6112" />

1. Check **Clone automation settings**.

1. Click **Create a Copy**.

1. Click **Edit** on the newly created enforcement set.

1. In the **Run this Enforcement Set on assets matching the following query** section, change the saved query to match the severity level:
   - **High**: <inject key="azureaduseremail" cloudname="Amazon Web Services" value=" Device Risk Open High Vulnerabilities (30d)" enableCopy="false" enableClickToPaste="false" style="color:#FF6112" />
   - **Medium**: <inject key="azureaduseremail" cloudname="Amazon Web Services" value=" Device Risk Open Medium Vulnerabilities (30d)" enableCopy="false" enableClickToPaste="false" style="color:#FF6112" />
   - **Low**: <inject key="azureaduseremail" cloudname="Amazon Web Services" value=" Device Risk Open Low Vulnerabilities (30d)" enableCopy="false" enableClickToPaste="false" style="color:#FF6112" />
   - **Other**: <inject key="azureaduseremail" cloudname="Amazon Web Services" value=" Device Risk Open Other Vulnerabilities (30d)" enableCopy="false" enableClickToPaste="false" style="color:#FF6112" />

1. In the **Main Action** section, select the action **Axonius - Add Custom Data to Assets** and update the **Field Value string** to match the severity level: **High**, **Medium**, **Low**, or **Other**.

1. Click **Save and Run**.

1. Change **Run Priority** to **4**.

1. Verify all enforcement sets are created and have run successfully (**Run History >** button up top).

    <br>

    <div>

     <img src="img/exposures_run_history.png" style="width: 800px !important; border: #000 1px outset">

    </div>

    <br>

---

<br>

## Task 7: Create Device Risk Scores

<blockquote class="overview">
  Risk scores in Axonius combine multiple factors to calculate an overall risk level for each device. In this task, you'll create two different risk scoring models: one focused on endpoint protection and another on vulnerability intelligence.
</blockquote>

### Part 1: Create the EPP Risk Score

1. Navigate to **Assets** > **Exposures** >**Security Findings**.

1. Click on **Risk Score >** at the top right.

1. In the Axonius Risk Score page, click on **+ Add Asset**.

1. Select **Devices** as the asset type.

1. Set **Action Name** to <inject key="azureaduseremail" cloudname="Amazon Web Services" value=" Device Risk Score EPP" enableCopy="false" enableClickToPaste="false" style="color:#FF6112" />

1. In the **What Devices is this relevant for?** section:
   - Select the saved query <inject key="azureaduseremail" cloudname="Amazon Web Services" value=" Devices with Vulnerability Visibility (30d)" enableCopy="false" enableClickToPaste="false" style="color:#FF6112" />

    <blockquote class="note">
      This ensures the risk score only applies to devices where you have vulnerability data, preventing inaccurate scoring for devices with limited visibility.
    </blockquote>

1. Set **Weighted Risk Score** to `per Device`.

1. In the **Score Calculation** section, add the following parameters:

    **Parameter 1: Query Condition - Critical Assets**

    - **Parameter Type**: Query Condition
    - **Asset Type**: Devices
    - **Query**: <inject key="azureaduseremail" cloudname="Amazon Web Services" value=" Critical Assets with Vulnerable Software Yes (30d)" enableCopy="false" enableClickToPaste="false" style="color:#FF6112" />
    - **Weight %**: 40

    Click **Edit risk score** and configure:
    - **IF** exists **THEN**: 10
    - **ELSE**: 0
    - Click **Apply**

    **Parameter 2: Query Condition - Internet Facing**

    - **Parameter Type**: Query Condition
    - **Asset Type**: Devices
    - **Query**: <inject key="azureaduseremail" cloudname="Amazon Web Services" value=" Internet Facing with Vulnerable Software Yes (30d)" enableCopy="false" enableClickToPaste="false" style="color:#FF6112" />
    - **Weight %**: 20

    Click **Edit risk score** and configure:
    - **IF** exists **THEN**: 10
    - **ELSE**: 0
    - Click **Apply**

    **Parameter 3: Query Condition - Unhealthy Endpoint Protection**

    - **Parameter Type**: Query Condition
    - **Asset Type**: Devices
    - **Query**: <inject key="azureaduseremail" cloudname="Amazon Web Services" value=" Endpoint Protection Healthy No (30d)" enableCopy="false" enableClickToPaste="false" style="color:#FF6112" />
    - **Weight %**: 20

    Click **Edit risk score** and configure:
    - **IF** exists **THEN**: 10
    - **ELSE**: 0
    - Click **Apply**

    **Parameter 4: Query Condition - CISA KEV Vulnerabilities**

    - **Parameter Type**: Query Condition
    - **Asset Type**: Devices
    - **Query**: <inject key="azureaduseremail" cloudname="Amazon Web Services" value=" Open CISA KEV Vulnerabilities Yes (30d)" enableCopy="false" enableClickToPaste="false" style="color:#FF6112" />
    - **Weight %**: 15

    Click **Edit risk score** and configure:
    - **IF** exists **THEN**: 10
    - **ELSE**: 0
    - Click **Apply**

    **Parameter 5: Asset Field - Vulnerability Severity**

    - **Parameter Type**: Asset Field
    - **Asset Type**: Devices
    - **Adapter**: Custom Data
    - **Field**: <inject key="azureaduseremail" cloudname="Amazon Web Services" value=" Exposures Device Risk Vulnerability Severity" enableCopy="false" enableClickToPaste="false" style="color:#FF6112" />
    - **Weight %**: 5

    Click **Edit risk score** and configure the **Alternative Value** conditions:
    - **IF** equals **Critical** **THEN**: 10
    - **ELSE IF** equals **High** **THEN**: 8
    - **ELSE IF** equals **Medium** **THEN**: 5
    - **ELSE IF** equals **Low** **THEN**: 2
    - **ELSE**: 0
    - Click **Apply**

    The final risk score should look like this:

    <br>

    <div>

     <img src="img/exposures_risk_score_epp.png" style="width: 700px !important; border: #000 1px outset">

    </div>

    <br>

1. In the **Risk Levels** section, configure the following levels:
   - 2.50 = **Low**
   - 5.90 = **Medium**
   - 7.90 = **High**
   - Infinity = **Critical**

   The final risk levels should look like this:

    <br>

    <div>

     <img src="img/exposures_risk_score_epp_levels.png" style="width: 500px !important; border: #000 1px outset">

    </div>

    <br>

1. Click **Save** (do not run yet).

1. Rename the risk score:
   - Click the three-dots menu (**⋮**) next to the risk score
   - Select **Rename Risk Score**
   - Enter: <inject key="azureaduseremail" cloudname="Amazon Web Services" value=" Device Risk Score EPP" enableCopy="false" enableClickToPaste="false" style="color:#FF6112" />
   - Press **Enter** to save

1. Click **Save and Run**.

    <blockquote class="note">
      The EPP (Endpoint Protection Platform) risk score emphasizes endpoint security health alongside vulnerability severity. Devices with unhealthy EPP agents receive higher risk scores even if they don't have critical vulnerabilities.
    </blockquote>

<br>

### Part 2: Create the SF Risk Score

1. In the Axonius Risk Score page, click on **+ Add Asset**.

1. Select **Devices** as the asset type.

1. Set **Action Name** to <inject key="azureaduseremail" cloudname="Amazon Web Services" value=" SF Risk Score EPP" enableCopy="false" enableClickToPaste="false" style="color:#FF6112" />

1. In the **What Devices is this relevant for?** section:
   - Select the saved query <inject key="azureaduseremail" cloudname="Amazon Web Services" value=" Devices with Vulnerability Visibility (30d)" enableCopy="false" enableClickToPaste="false" style="color:#FF6112" />

    <blockquote class="note">
      This ensures the risk score only applies to devices where you have vulnerability data, preventing inaccurate scoring for devices with limited visibility.
    </blockquote>

1. Set **Weighted Risk Score** to `per Security Finding per Device`.

1. In the **Score Calculation** section, add the following parameters:

    **Parameter 1: Query Condition - Critical Assets**

    - **Parameter Type**: Query Condition
    - **Asset Type**: Devices
    - **Query**: <inject key="azureaduseremail" cloudname="Amazon Web Services" value=" Critical Assets with Vulnerable Software Yes (30d)" enableCopy="false" enableClickToPaste="false" style="color:#FF6112" />
    - **Weight %**: 40

    Click **Edit risk score** and configure:
    - **IF** exists **THEN**: 10
    - **ELSE**: 0
    - Click **Apply**

    **Parameter 2: Query Condition - Internet Facing**

    - **Parameter Type**: Query Condition
    - **Asset Type**: Devices
    - **Query**: <inject key="azureaduseremail" cloudname="Amazon Web Services" value=" Internet Facing with Vulnerable Software Yes (30d)" enableCopy="false" enableClickToPaste="false" style="color:#FF6112" />
    - **Weight %**: 20

    Click **Edit risk score** and configure:
    - **IF** exists **THEN**: 10
    - **ELSE**: 0
    - Click **Apply**

    **Parameter 3: Query Condition - Unhealthy Endpoint Protection**

    - **Parameter Type**: Query Condition
    - **Asset Type**: Devices
    - **Query**: <inject key="azureaduseremail" cloudname="Amazon Web Services" value=" Endpoint Protection Healthy No (30d)" enableCopy="false" enableClickToPaste="false" style="color:#FF6112" />
    - **Weight %**: 20

    Click **Edit risk score** and configure:
    - **IF** exists **THEN**: 10
    - **ELSE**: 0
    - Click **Apply**

    **Parameter 4: Asset Field - CISA KEV Vulnerabilities exists**

    - **Parameter Type**: Asset Field
    - **Asset Type**: Aggregated Security Findings
    - **Adapter**: CISA Known Exploited Vulnerabilities
    - **Field**: ID
    - **Weight %**: 15

    Click **Edit risk score** and configure:
    - **IF** exists **THEN**: 10
    - **ELSE**: 0
    - Click **Apply**

    **Parameter 5: Asset Field - Vulnerability Severity (from Security Findings)**

    - **Parameter Type**: Asset Field
    - **Asset Type**: Aggregated Security Findings
    - **Adapter**: Axonius Aggregated
    - **Field**: Severity
    - **Weight %**: 5

    Click **Edit risk score** and configure the **Alternative Value** conditions:
    - **IF** in (equals) **CRITICAL**, **SEVERE** **THEN**: 10
    - **ELSE IF** equals **HIGH** **THEN**: 8
    - **ELSE IF** in (equals) **MEDIUM**, **MODERATE** **THEN**: 5
    - **ELSE IF** equals **LOW** **THEN**: 2
    - **ELSE**: 0
    - Click **Apply**

    The final risk score should look like this:

    <br>

    <div>

     <img src="img/exposures_risk_score_vi.png" style="width: 700px !important; border: #000 1px outset">

    </div>

    <br>

1. In the **Risk Levels** section, configure the following ranges:
   - 2.50 = **Low**
   - 5.90 = **Medium**
   - 7.90 = **High**
   - Infinity = **Critical**

   The final risk levels should look like this:

    <br>

    <div>

     <img src="img/exposures_risk_score_epp_levels.png" style="width: 500px !important; border: #000 1px outset">

    </div>

    <br>

1. Click **Save** (do not run yet).

1. Rename the risk score:
   - Click the three-dots menu (**⋮**) next to the risk score
   - Select **Rename Risk Score**
   - Enter: <inject key="azureaduseremail" cloudname="Amazon Web Services" value=" SF Risk Score EPP" enableCopy="false" enableClickToPaste="false" style="color:#FF6112" />
   - Press **Enter** to save

1. Click **Save and Run**.

    <blockquote class="note">
      The SF (Security Findings) risk score focuses more heavily on vulnerability data from security findings rather than custom fields. This approach works well when you have high-quality vulnerability scanner data.
    </blockquote>

1. Wait for both risk scores to complete their calculations.

<question source="https://docs-api.cloudlabs.ai/repos/raw.githubusercontent.com/Axonius/academy/refs/heads/main/gko2027/questions/_q2_risk_score_max.md" />

<br>

---

<br>

## Task 8: Review and Customize Dashboards

<blockquote class="overview">
  Now that your risk scores and custom fields are configured, it's time to review the Exposures dashboards and verify they're displaying accurate data. You'll also learn how to customize them for your environment.
</blockquote>

1. Navigate to **Dashboards** in the left-side menu.

1. Open your <inject key="azureaduseremail" cloudname="Amazon Web Services" value=" Exposures: Executive Dashboard" enableCopy="false" enableClickToPaste="false" style="color:#FF6112" /> dashboard.

1. Review the dashboard charts and verify data is populating correctly.

    <blockquote class="note">
      If some charts appear empty, it may be because the enforcement sets and risk scores are still processing. Wait a few minutes and refresh the dashboard.
    </blockquote>

1. Locate the <inject key="azureaduseremail" cloudname="Amazon Web Services" value=" Exposures: Implementation Help Charts" enableCopy="false" enableClickToPaste="false" style="color:#FF6112" /> dashboard.

1. Open this dashboard and find the chart titled **DELETE THIS CHART**.

1. Click the three-dots menu on the chart and select **Delete**.

    <blockquote class="note">
      This placeholder chart was included in the template to help with initial setup. Now that your configuration is complete, you can remove it.
    </blockquote>

1. Return to your **Executive Dashboard** and explore the various charts:
   - **Internet Facing Devices**: Shows devices accessible from the internet
   - **Security Findings by CVSS Severity**: Displays open vulnerabilities by severity level
   - **CISA KEV by Product**: Highlights known exploited vulnerabilities

    <br>

    <div>

     <img src="img/exposures_executive_dashboard.png" style="width: 900px !important; border: #000 1px outset">

    </div>

    <br>

## Task 9: Understanding SLA and Exception Management

<blockquote class="overview">
  Exposures includes SLA tracking and exception management capabilities to help you manage vulnerability remediation timelines and handle special cases. In this task, you'll explore these features.
</blockquote>

1. Navigate to **Assets** > **Security Findings** and click on **SLA Management**.

1. Review the default SLA timelines for different risk levels:
   - Critical Risk: Typically 7-30 days
   - High Risk: Typically 30-90 days
   - Medium Risk: Typically 90-180 days
   - Low Risk: Typically 365 days

    <blockquote class="note">
      These SLA timelines can be customized based on your organization's security policies and compliance requirements.
    </blockquote>

<question source="https://docs-api.cloudlabs.ai/repos/raw.githubusercontent.com/Axonius/academy/refs/heads/main/gko2027/questions/_q3_sla_timestamp.md" />

<br>

### Understanding Exception Management

1. Navigate to **Exposures** > **Exception Management**.

1. Notice that the **Create Exception** button is greyed out.

<question source="https://docs-api.cloudlabs.ai/repos/raw.githubusercontent.com/Axonius/academy/refs/heads/main/gko2027/questions/_q4_exception_button.md" />

    <blockquote class="note">
      Exception management allows you to document and track cases where vulnerabilities cannot be remediated immediately due to business constraints, technical limitations, or compensating controls. This helps maintain compliance while acknowledging real-world operational challenges.
    </blockquote>


<br>

---

<br>

## Summary and Key Takeaways

<blockquote class="overview">
  Congratulations! You've successfully deployed and configured Axonius Exposures. Let's review what you've accomplished and the key concepts you've learned.
</blockquote>

### What You've Accomplished

In this lab, you have:

* ✅ Verified and configured adapters for Exposures data collection
* ✅ Created custom fields to track vulnerability severity
* ✅ Built Action Center enforcement sets to automate device tagging
* ✅ Configured two different risk scoring models (EPP and VI)
* ✅ Deployed and customized Exposures dashboards
* ✅ Reviewed and understood base queries for critical assets, active devices, and vulnerability visibility
* ✅ Explored SLA management and exception handling

### Key Concepts

**Risk Scoring**: Axonius risk scores combine multiple factors (vulnerability severity, asset criticality, internet exposure, endpoint protection health) to provide a holistic view of device risk.

**Custom Fields and Automation**: By combining custom fields with Action Center enforcement sets, you can automatically categorize and tag assets based on complex criteria.

**Data Source Configuration**: Proper adapter configuration is critical for Exposures. Many adapters require specific advanced settings to fetch vulnerability and security findings data.

**Query Customization**: The base queries (Active Devices, Critical Assets, Internet Facing, Vulnerability Visibility) must be customized for each environment to ensure accurate risk assessment.

**Remediation Ownership**: Exposures supports team-specific dashboards and workflows, enabling distributed remediation responsibility across the organization.

### Next Steps

In a production deployment, you would:

1. **Refine your queries** based on actual customer data and business requirements
2. **Customize SLA timelines** to match organizational security policies
3. **Create remediation workflows** using Action Center to automatically assign and track vulnerability remediation
4. **Set up exception management** rules and approval processes
5. **Integrate with ticketing systems** (Jira, ServiceNow) for automated ticket creation and tracking
6. **Schedule regular dashboard reviews** with security and IT teams

<br>

### Additional Resources

- **Axonius Exposures Documentation**: [docs.axonius.com/docs/exposures](https://docs.axonius.com/docs/exposures)
- **Network Routes Configuration**: Check the Confluence page for adapter-specific requirements
- **Risk Scoring Best Practices**: Consult with your Axonius CSM for industry-specific recommendations

<br>

---

<br>

## Final Knowledge Check

Test your understanding of the Exposures implementation:

**Question 1**: What are two good reasons to upgrade Axonius to the latest build before enabling Exposures?

**Answer**: Bug fixes and new features utilized in Exposures

<br>

**Question 2**: Why would Mandiant Enrichment be a useful data source for Exposures?

**Answer**: It enriches Devices and Aggregated Security Findings with CVE information from Mandiant, providing additional context for risk scoring and vulnerability prioritization

<br>

**Question 3**: What is the purpose of setting different run priorities for the enforcement sets?

**Answer**: The reset enforcement set runs first (priority 3) to clear all values, then the specific severity enforcement sets run afterward (priority 4+) to ensure each device gets tagged with only its highest severity vulnerability

<br>

➡️ Proceed to the **Next** page.

</div>

<br>
<br>

# +
*** Settings ***
Documentation   Template robot main suite. 
Library         RPA.Browser
Library         RPA.HTTP
Library         RPA.Excel.Files
Library         RPA.PDF
Library         RPA.Tables
Library         RPA.FileSystem
Library         RPA.Archive
Library         RPA.Dialogs
Library         Dialogs
Library         BuiltIn
Library         RPA.Robocloud.Secrets
Library         RPA.Robocloud 
#Library         RPA.Robocorp.Vault




# +
*** Variables ***
#${CSV_FILE_URL}=    https://robotsparebinindustries.com/orders.csv
${GLOBAL_RETRY_AMOUNT}=    10x
${GLOBAL_RETRY_INTERVAL}=    1s


# -

*** Keywords ***
success Dialogs
     
    #Add icon    success 
    #Add heading     ur orser have been processed
    ${URL} =	Get Value From User	    please enter the csv url 
    Download               ${URL}      overwrite=True

*** Keywords ***
open the website
    ${secrets}=    Get Secret    robotbin
    Log       ${secrets}
    Open Available Browser            ${secrets}[url]   #https://robotsparebinindustries.com/  # ${secrets}[url]     #https://robotsparebinindustries.com/          
    #Maximize Browser Window


*** Keywords ***
Log In
   
   Input Text    username           maria
   Input Password    password        thoushallnotpass
   Submit Form
   Click Link                   link:Order your robot! 
   
   
   #wait Until Page Contains Element    id:sales-form

*** Keywords ***
Download The File 
    Download               ${URL}      overwrite=True       # https://robotsparebinindustries.com/orders.csv



# +
*** Keywords ***
Read CSV
    ${Table}        Read Table From Csv             orders.csv
    FOR     ${orders_r}    IN    @{Table}
        Click Button                 OK
        
        Fill And Submit The Form For One order    ${orders_r}
    END
    
    
# -

*** Keywords ***
Read CSVfile
    ${Table}        Read Table From Csv             orders.csv
    FOR     ${orders_r}    IN    @{Table}
        Log     ${orders_r}
    END
    
     [Return]        ${Table} 

# +
*** Keywords ***
Close the annoying modal
    Click Button    OK


# -

*** Keywords ***
Fill And SubmitTheForm For One order
    [Arguments]    ${orders_r}
    #   Wait Until Element Is Visible    id:root
    ${Head_as_string}=    Convert To String    ${orders_r}[Head]
    Select From List By Value    head    ${Head_as_string}
    #${Body_as_string}=    Convert To String    ${orders_r}[Body]
    #Select From List By Value    css:div.stacked    ${Body_as_string}
    #IF    ${orders_r}[Body] == 2
    Select Radio Button     body          ${orders_r}[Body]
    #END
    #${Legs_as_string}=    Convert To String    ${orders_r}[Legs]
    #Select From List By Value    form-group    ${Legs_as_string}
    Input Text     css:input.form-control    ${orders_r}[Legs]
    Input Text    address    ${orders_r}[Address]

*** Keywords ***
Preview the robot
    Click Element    id:preview
    Wait Until Element Is Visible    id:robot-preview


*** Keywords ***
Submit the order And Keep Checking Until Success
    Click Element    order
    Element Should Be Visible    xpath://div[@id="receipt"]/p[1]
    Element Should Be Visible    id:order-completion

*** Keywords ***
Submit the order
    Wait Until Keyword Succeeds    ${GLOBAL_RETRY_AMOUNT}    ${GLOBAL_RETRY_INTERVAL}     Submit the order And Keep Checking Until Success


*** Keywords ***
Take a screenshot of the robot
    [Arguments]    ${order_number}
    Screenshot     id:robot-preview    ${CURDIR}${/}output${/}${order_number}.png
    [Return]       ${CURDIR}${/}output${/}${order_number}.png


*** Keywords ***
Store the receipt as a PDF file
    [Arguments]    ${order_number}
    Wait Until Element Is Visible    id:order-completion
    ${order_number}=    Get Text    xpath://div[@id="receipt"]/p[1]
    #Log    ${order_number}
    ${receipt_html}=    Get Element Attribute    id:order-completion    outerHTML
    Html To Pdf    ${receipt_html}    ${CURDIR}${/}output${/}receipts${/}${order_number}.pdf
    [Return]    ${CURDIR}${/}output${/}receipts${/}${order_number}.pdf

*** Keywords ***
Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}   ${pdf}
    Open Pdf       ${pdf}
    Add Watermark Image To Pdf    ${screenshot}    ${pdf}
    Close Pdf      ${pdf}




# +
*** Tasks ***
Minimal task
    success Dialogs
    open the website
    Log In
    ${orders} =     Read CSVfile
    FOR    ${row}    IN    @{orders}
       Close the annoying modal
        Fill And SubmitTheForm For One order    ${row}
         Preview the robot
         Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts
    [Teardown]      Close Browser


# -





*** Keywords ***
Fill And Submit The Form For One order
    [Arguments]    ${orders_r}
    #   Wait Until Element Is Visible    id:root
    ${Head_as_string}=    Convert To String    ${orders_r}[Head]
    Select From List By Value    head    ${Head_as_string}
    #${Body_as_string}=    Convert To String    ${orders_r}[Body]
    #Select From List By Value    css:div.stacked    ${Body_as_string}
    #IF    ${orders_r}[Body] == 2
    Select Radio Button     body          ${orders_r}[Body]
    #END
    #${Legs_as_string}=    Convert To String    ${orders_r}[Legs]
    #Select From List By Value    form-group    ${Legs_as_string}
    Input Text     css:input.form-control    ${orders_r}[Legs]
    Input Text    address    ${orders_r}[Address]
    
    
     #wait Until Page Contains Element    id:root
     #sleep     5
    #Click Button    preview
    #Sleep	 5
    Click Element    id:preview
    Wait Until Element Is Visible    id:robot-preview
    Click Element    order
    Element Should Be Visible    xpath://div[@id="receipt"]/p[1]
    Element Should Be Visible    id:order-completion

    
    #wait Until Page Contains Element    id:robot-preview
     #Click Button    order
      #Sleep	   5
     #wait Until Page Contains Element    id:receipt
   
    #Click Button    order
    ${Screenshot}=       Screenshot      robot-preview      ${CURDIR}${/}output${/}${orders_r}[Order number].png
    #Wait Until Element Is Visible    id:receipt
    ${order_results_html}    Get Element Attribute    id:receipt    outerHTML
    ${PDF}   Html To Pdf    ${order_results_html}    ${CURDIR}${/}output${/}${orders_r}[Order number].pdf
    
     Add Watermark Image To Pdf    ${CURDIR}/output${/}${orders_r}[Order number].png   ${CURDIR}/output${/}${orders_r}[Order number].PDF  ${CURDIR}/output${/}${orders_r}[Order number].PDF
     ${receipts}    Remove File   ${CURDIR}/output${/}${orders_r}[Order number].png
     
        
     
     Archive Folder With Zip        ${CURDIR}${/}output      receipts_archi.zip     
     Add To Archive     ${CURDIR}/output${/}${orders_r}[Order number].PDF          receipts_archi.zip
   
    #Add Files To Pdf        ${Screenshot}            ${CURDIR}${/}output${/}newpdf.pdf
    #Click Button         Order another robot 
    Click Button    order-another

#*** Tasks ***
Minimal task
    success Dialogs
     #Download The File
    open the website
    Log In
    Read CSV
    Fill And Submit The Form For One order
    #open the robotwebsite











*** Settings ***
Documentation       Fill the order according to cvs file.
...                 Save the order HTML receipt as a PDF file
...                 Save the screenchot of the ordered robot
...                 Embed the screenshot of the robot to the PDF receipt
...                 creates ZIP archive of the receipts and the images

Library             RPA.Browser.Selenium
Library             RPA.Netsuite
Library             RPA.Tables
Library             RPA.MSGraph
Library             RPA.Excel.Files
Library             RPA.HTTP
Library             RPA.PDF
Library             XML
Library             RPA.Archive
Library             RPA.FileSystem


*** Variables ***
# static variables can;t be change dyanmicly
${CSV_FILE_NAME}=       orders.csv
${EXCELL_FILE_URL}=     https://robotsparebinindustries.com/orders.csv


*** Tasks ***
Order robots form RobotsSpareBin Industries Inc.
# Todo: implements your keywords
    Create folders
    Download excell file
    create orders
    Zip folders


*** Keywords ***
Create folders
    Create Directory    ${OUTPUT_DIR}${/}robots
    Create Directory    ${OUTPUT_DIR}${/}receipts

Download excell file
    Download    ${EXCELL_FILE_URL}    overwrite=True

Read excel file
    ${orders}=    Read table from CSV    ${CSV_FILE_NAME}
    RETURN    ${orders}

Create orders
    ${orders}=    read excel file
    Log To Console    ${orders}
    FOR    ${order}    IN    @{orders}
        Order robot    ${order}
    END

Order robot
    [Arguments]    ${order}

    Open Available Browser    https://robotsparebinindustries.com/#/robot-order
    Click Button    xpath://*[@id="root"]/div/div[2]/div/div/div/div/div/button[3]
    Log To Console    ${order}
    Select From List By Value    id:head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    class:form-control    ${order}[Legs]
    Input Text    id:address    ${order}[Address]

    Wait Until Keyword Succeeds    10x    3s    Click Order robot

    ${pdf}=    Store the order receipt as a PDF file    ${order}[Order number]
    ${screenshot}=    Take a screenshot of the robot    ${order}[Order number]
    @{files}=    Create List    ${screenshot}    ${pdf}
    Embed robot to receipt    @{files}    reciept_number=${order}[Order number]

Click Order robot
    Click Button    id:preview
    Click Button    id:order
    Wait Until Page Contains    Receipt

Store the order receipt as a PDF file
    [Arguments]    ${order_number}
    ${RECEIPT_FOLDER}=    Set Variable    ${OUTPUT_DIR}${/}receipts
    ${ROBOTS_FOLDER}=    Set Variable    ${OUTPUT_DIR}${/}robots
    ${pdf}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${pdf}    ${RECEIPT_FOLDER}${/}${order_number}.pdf
    RETURN    ${RECEIPT_FOLDER}${/}${order_number}.pdf

Take a screenshot of the robot
    [Arguments]    ${order_number}
    ${RECEIPT_FOLDER}=    Set Variable    ${OUTPUT_DIR}${/}receipts
    ${ROBOTS_FOLDER}=    Set Variable    ${OUTPUT_DIR}${/}robots
    # ${screenshot}=    Get Element Attribute    id:robot-preview-image    outerHTML
    Screenshot    id:robot-preview-image    ${ROBOTS_FOLDER}${/}${order_number}.png
    RETURN    ${ROBOTS_FOLDER}${/}${order_number}.png

Embed robot to receipt
    [Arguments]    @{files}    ${reciept_number}=
    ${RECEIPT_FOLDER}=    Set Variable    ${OUTPUT_DIR}${/}receipts
    ${ROBOTS_FOLDER}=    Set Variable    ${OUTPUT_DIR}${/}robots
    Add files to pdf    ${files}    ${RECEIPT_FOLDER}${/}merged_${reciept_number}.pdf

Zip folders
    ${RECEIPT_FOLDER}=    Set Variable    ${OUTPUT_DIR}${/}receipts
    ${ROBOTS_FOLDER}=    Set Variable    ${OUTPUT_DIR}${/}robots
    Archive Folder With Zip    ${RECEIPT_FOLDER}    ${OUTPUT_DIR}${/}RECEIPTS.ZIP
    Archive Folder With Zip    ${ROBOTS_FOLDER}    ${OUTPUT_DIR}${/}ROBOTS.ZIP

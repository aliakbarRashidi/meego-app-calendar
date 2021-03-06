/*
 * Copyright 2011 Intel Corporation.
 *
 * This program is licensed under the terms and conditions of the
 * Apache License, version 2.0.  The full text of the Apache License is at 	
 * http://www.apache.org/licenses/LICENSE-2.0
 */

import Qt 4.7
import MeeGo.Labs.Components 0.1 as Labs
import MeeGo.App.Calendar 0.1
import MeeGo.Components 0.1
import MeeGo.Connman 0.1

ModalDialog {
    id:outer
    title:container.titleBlockText

    property int windowType:0
    property bool initView:false
    property bool editView:false

    property int eventDay
    property int eventMonth
    property int eventYear
    property int eventStartHr
    property int eventEndHr
    property bool isAllDay
    property string editEventId
    property int paintedTextMaxWidth:500
    property int outerPainterTextWidth : 2*(paintedTextMaxWidth / 3)
    property int paintedMaxWidth:2*(topItem.topWidth/3)

    signal close();

    function editEvent() {
        if(editView) {
            container.initializeModifyView(editEventId);
            editView = false;
        }
    }

    function newEvent() {
        if(initView) {
            container.initializeView(eventDay,eventMonth,eventYear,eventStartHr,eventEndHr,isAllDay);
            initView = false;
        }
    }

    showCancelButton: false
    showAcceptButton: false

    TopItem { id: topItem }
    height: container.height + decorationHeight
    width: container.width

    content:Item {
        id: container
        height:scrollableSection.height+titleBlock.height+50
        width:(window.inLandscape||window.inInvertedLandscape)? 600: 2*(topItem.topWidth/3)
        clip: true

        property bool initView:outer.initView
        property bool editView:outer.editView

        property int windowType:outer.windowType
        property bool allDaySet:false
        property string eventTitle
        property string titleBlockText
        property string startDateStr
        property string endDateStr
        property string startTimeStr
        property string endTimeStr
        property date startDate
        property date endDate
        property date repeatEndDate
        property variant startTime
        property variant endTime
        property string uid
        property variant editEvent
        property int repeatType
        property int alarmType

       function setEndRepeatDateValues() {
            endRepeatDayText.text = finishDateTxt.text;
        }

        function  validateInputs() {
            var validData = true;

            if(!container.allDaySet) {
                validData = validateDateTime(startDate,endDate,startTime,endTime);
            }

            if(!validData) {
               confirmDialog.show();
            }
            return validData;
        }

        function validateDateTime(date1,date2,time1,time2) {
            var isValid = true;
            if(!allDayCheck.on) {
                var compareDatesVal = utilities.compareDates(date1,date2);
                var compareTimesVal = utilities.compareTimes(time1,time2);

                if(compareDatesVal==2) {
                    isValid=false;
                } else {
                    if(compareTimesVal==2 || compareTimesVal==0) {
                        if(compareDatesVal==1)
                            isValid = true;
                        else
                            isValid = false;
                    } else {
                        isValid = true;
                    }
                }
            }
            return isValid;
        }

        Labs.TimezoneListModel {
            id: timezoneModel
        }

        ClockModel {
            id: clockModel
        }

        Labs.TimezonePicker {
            id: tzPicker
            currentLocation: clockModel.timezone
            gmtName: timezoneModel.getLocationName(clockModel.timezone)
            onTimezoneSelected: {
                tzCmb.gmtName = gmtName;
                tzCmb.gmtOffset = gmtOffset;
                tzCmb.gmtTitle = locationName;
            }
        }

       ModalDialog {
            id:confirmDialog
            title :qsTr("Error")
            buttonHeight: 35
            showCancelButton: false
            showAcceptButton: true
            acceptButtonText: qsTr( "OK" )
            alignTitleCenter:true

            content: Item {
                id: myContent
                anchors.fill:parent
                anchors.margins: 10
                Text {
                    id:confirmMsg
                    text: qsTr("Please check the date and time entered")
                    anchors.fill:parent
                    wrapMode:Text.Wrap
                    font.pixelSize: theme_fontPixelSizeLarge
                }
            }

            onAccepted: {
                confirmDialog.hide();
            }

        }//end confirmDialog

        function createIOObject() {
            //Initialize variables
            var repeatEndDateVal="";
            var repeatCnt = 0;
            var isAllDay = false;
            eventIO.repeatType = UtilMethods.ENoRepeat;
            eventIO.repeatEndType = UtilMethods.EForever;
            eventIO.alarmType = UtilMethods.ENoAlarm;

            //Now actually set the event values
            eventIO.type = UtilMethods.EEvent;
            eventIO.uid = uid;
            eventIO.description = notesInputText.text;
            eventIO.summary = eventTitleText.text;
            eventIO.location = locInputText.text;
            if(allDayCheck.on) {
                isAllDay=true;
            } else {
                isAllDay=false;
            }
            eventIO.allDay = isAllDay;

            if(eventIO.allDay ) {
                eventIO.setStartDateTime(startDate,"",tzCmb.gmtTitle);
            } else if(!eventIO.allDay ) {
                eventIO.setStartDateTime(startDate,startTime,tzCmb.gmtTitle);
                eventIO.setEndDateTime(endDate,endTime,tzCmb.gmtTitle);
            }
            eventIO.zoneOffset = tzCmb.gmtOffset;

            eventIO.repeatType = repeatCmbBlock.repeatType;
            eventIO.repeatEndType = repeatEndComboBox.repeatEndType;

            if(eventIO.repeatType != UtilMethods.ENoRepeat) {
                if(eventIO.repeatEndType == UtilMethods.EForNTimes) {
                    if(repeatCountText.text!="") {
                        repeatCnt = parseInt(repeatCountText.text);
                        eventIO.repeatCount = repeatCnt;
                    }
                } else if(eventIO.repeatEndType == UtilMethods.EAfterDate) {
                    if(endRepeatDayText.text!="") {
                        eventIO.setRepeatEndDateTime(repeatEndDate, endTime,tzCmb.gmtTitle);
                    }
                } else if(eventIO.repeatEndType == UtilMethods.EForever) {

                }
            }

            eventIO.alarmType = alarmCmb.selectedIndex;

            if(windowType == UtilMethods.EAddEvent) {
                controller.addModifyEvent(UtilMethods.EAddEvent,eventIO);
            } else if(windowType == UtilMethods.EModifyEvent) {
                controller.addModifyEvent(UtilMethods.EModifyEvent,eventIO);
            }

            window.addedEvent = true;
        }


        function initializeView(eventDay,eventMonth,eventYear,eventStartHr,eventEndHr,isAllDay) {
            titleBlockText = qsTr("New event");
            //Clear all the initial Values
            eventTitleText.text = "";
            startDateTxt.text = "";
            finishDateTxt.text = "";
            startTimeTxt.text = "";
            finishTimeTxt.text = "";

            if(eventDay==0 ||eventMonth==0 ||eventYear==0) {
                startDate = utilities.getCurrentDateVal();
                endDate = utilities.getCurrentDateVal();
                startDateStr = i18nHelper.localDate(startDate, Labs.LocaleHelper.DateFullShort);
                endDateStr = i18nHelper.localDate(endDate, Labs.LocaleHelper.DateFullShort);
            } else {
                startDate = utilities.createDateFromVals(eventDay,eventMonth,eventYear);
                startDateStr=i18nHelper.localDate(startDate, Labs.LocaleHelper.DateFullShort);
                endDate = startDate;
                endDateStr = startDateStr;
            }

            if(isAllDay) {
                allDayCheck.on = true;
            } else {
                allDayCheck.on = false;
            }

            if(eventStartHr==-1 || eventEndHr==-1) {
                startTime = utilities.getCurrentTimeVal();
                startTime = utilities.roundTime(startTime);
                startTimeStr = i18nHelper.localTime(startTime, Labs.LocaleHelper.TimeFull);
                endTime = utilities.addHMToCurrentTime(1,0);
                endTime = utilities.roundTime(endTime);
                endTimeStr = i18nHelper.localTime(endTime, Labs.LocaleHelper.TimeFull);
            } else {
                startTime = utilities.createTimeFromVals(eventStartHr,0);
                startTimeStr = i18nHelper.localTime(startTime, Labs.LocaleHelper.TimeFull);

                var eventEndTimeStr = eventEndHr.toString();
                if(eventEndTimeStr.length > 3) {
                    endTime = utilities.createTimeFromVals(parseInt(eventEndTimeStr.substr(0,2)),parseInt(eventEndTimeStr.substr(2,2)));
                } else {
                    endTime = utilities.createTimeFromVals(parseInt(eventEndTimeStr.substr(0,1)),parseInt(eventEndTimeStr.substr(1,2)));
                }
                endTimeStr = i18nHelper.localTime(endTime, Labs.LocaleHelper.TimeFull);
            }

            startDateTxt.text = startDateStr;
            finishDateTxt.text = endDateStr;
            startTimeTxt.text = startTimeStr;
            finishTimeTxt.text = endTimeStr;
            alarmCmb.selectedIndex=0;
            repeatCmb.selectedIndex=0;
        }

        function initializeModifyView(eventId)
        {
            titleBlockText = "";
            uid = eventId;
            editEvent = controller.getEventForEdit(eventId);
            eventTitleText.text = editEvent.summary;
            notesInputText.text = editEvent.description;
            locInputText.text = editEvent.location;
            if(editEvent.allDay) {
                allDayCheck.on = true;
            } else {
                allDayCheck.on = false;
            }

            startDate = editEvent.getStartDateFromKDT();
            endDate = editEvent.getEndDateFromKDT();
            startTime = editEvent.getStartTimeFromKDT();
            endTime = editEvent.getEndTimeFromKDT();

            startDateTxt.text = i18nHelper.localDate(startDate, Labs.LocaleHelper.DateFullShort);
            finishDateTxt.text = i18nHelper.localDate(endDate, Labs.LocaleHelper.DateFullShort);
            startTimeTxt.text = i18nHelper.localTime(startTime, Labs.LocaleHelper.TimeFull);
            finishTimeTxt.text = i18nHelper.localTime(endTime, Labs.LocaleHelper.TimeFull);

            container.allDaySet = allDayCheck.on;
            startDateStr= startDateTxt.text;
            endDateStr = finishDateTxt.text;
            startTimeStr = startTimeTxt.text;
            endTimeStr = finishTimeTxt.text;

            container.repeatType = editEvent.repeatType;
            container.alarmType = editEvent.alarmType;

            alarmCmb.selectedTitle = utilities.getAlarmString(editEvent.alarmType);
            alarmCmb.selectedIndex = editEvent.alarmType;
            repeatCmb.selectedIndex = editEvent.repeatType;
            repeatCmb.selectedTitle = utilities.getRepeatTypeString(editEvent.repeatType);
            repeatEndCmb.selectedIndex = editEvent.repeatEndType;
            repeatEndCmb.selectedTitle = utilities.getRepeatEndTypeString(editEvent.repeatEndType);

            if(editEvent.repeatType != UtilMethods.ENoRepeat) {
                if(editEvent.repeatEndType == UtilMethods.EForNTimes) {
                    repeatCountText.text= editEvent.repeatCount.toString();
                }
                else if(editEvent.repeatEndType == UtilMethods.EAfterDate) {
                    endRepeatDayText.text = editEvent.getRepeatEndDateFromKDT(UtilMethods.EDefault);
                }
            }
        }

        function openTimePicker(index,parentVal)
        {
            timePicker.fromIndex = index;
            if(index ==1) {
                timePicker.hours = utilities.getHour(startTime);
                timePicker.minutes = utilities.getMin(startTime);
            } else if(index ==2) {
                timePicker.hours = utilities.getHour(endTime);
                timePicker.minutes = utilities.getMin(endTime);
            }
            timePicker.show();
        }

        function formatInteger(intVal)
        {
            var intValStr="";
            if(intVal<10) {
                intValStr = "0";
            }
            intValStr += intVal.toString();
            return intValStr;
        }

        function setTimeValues(fromIndex,timeVal)
        {
            if(fromIndex==1) {
                startTime = timeVal;
                startTimeTxt.text = i18nHelper.localTime(startTime, Labs.LocaleHelper.TimeFull);
                //Temporary Fix to bug BMC:17374
                startTimeTxt.visible=false;
                startTimeTxt.visible=true;
            } else if(fromIndex==2) {
                endTime = timeVal;
                finishTimeTxt.text = i18nHelper.localTime(endTime, Labs.LocaleHelper.TimeFull);
                //Temporary Fix to bug BMC:17374
                finishTimeTxt.visible=false;
                finishTimeTxt.visible=true;
            }
        }

        function openDatePicker(index,parentVal)
        {
            datePicker.fromIndex = index;
            datePicker.show();
        }


        function setDateValues(fromIndex,dateVal)
        {
            if(fromIndex == 1) {
                startDate = dateVal;
                startDateTxt.text=i18nHelper.localDate(startDate, Labs.LocaleHelper.DateFullShort);
                //Temporary Fix to bug BMC:17374
                startDateTxt.visible=false;
                startDateTxt.visible=true;
            } else if(fromIndex == 2) {
                endDate = dateVal;
                finishDateTxt.text = i18nHelper.localDate(endDate, Labs.LocaleHelper.DateFullShort);
                //Temporary Fix to bug BMC:17374
                finishDateTxt.visible=false;
                finishDateTxt.visible=true;
            } else if(fromIndex == 3) {
                repeatEndDate = dateVal;
                endRepeatDayText.text = i18nHelper.localDate(repeatEndDate, Labs.LocaleHelper.DateFullShort);
                //Temporary Fix to bug BMC:17374
                endRepeatDayText.visible=false;
                endRepeatDayText.visible=true;
            }
        }



        DatePicker {
            id:datePicker
            property date dateVal
            property int fromIndex:0
            startYear: 1980
            endYear: 2019

            onDateSelected: {
                dateVal=datePicker.selectedDate;
                container.setDateValues(fromIndex,dateVal);
            }
        }

        TimePicker {
            id: timePicker
            property int fromIndex:0
            property variant timeVal
            onAccepted: {
                timeVal = utilities.createTimeFromVals(hours,minutes);
                container.setTimeValues(fromIndex,timeVal);
            }
            minutesIncrement:5
            //hr24:i18nHelper.defaultTimeFormat
        }

        CalendarController {
            id: controller
        }

        IncidenceIO {
            id: eventIO
        }

        UtilMethods {
            id:utilities
        }

        Labs.LocaleHelper {
            id:i18nHelper
        }

        Item {
            id: editList
            anchors.fill: parent
            property int innerBoxWidth: width-50
            property bool windowExpanded:false


            MouseArea {
                anchors.fill: parent
                onClicked: {}
            }
            Behavior on opacity {
                PropertyAnimation { duration: 250 }
            }

            //Title Block
            Item {
                id: titleBlock
                width: editList.innerBoxWidth
                height:titleEditArea.height
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.topMargin: 10
                anchors.leftMargin: 25

                Item {
                    id:titleEditArea
                    anchors.top:parent.top
                    width: parent.width
                    height: 30
                    TextEntry {
                        id: eventTitleText
                        defaultText: qsTr("Event title")
                        anchors.fill: parent
                    }
                }

            }//end title item

            //Title divider
            Image {
                id:titleDivBox
                width: parent.width
                anchors.top: titleBlock.bottom
                anchors.left: parent.left
                anchors.topMargin: 10
                source: "image://themedimage/images/menu_item_separator"
            } //end of titleDivider


            //Scrollable EditArea
           Flickable {
               id:scrollableEditArea
                flickableDirection: Flickable.VerticalFlick
                width: editList.width
                height: (editList.height-titleBlock.height-50)
                contentWidth: scrollableSection.width
                contentHeight:scrollableSection.height
                anchors.top: titleDivBox.bottom
                anchors.topMargin: 5
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                clip: true
                interactive: false
                boundsBehavior: Flickable.StopAtBounds

                property bool flickableExpanded:false

                Item {
                    id: scrollableSection
                    width: editList.width
                    height:(dateTimeBox.height+dateTimeBlock.height+moreBlock.height)
                    anchors.top: parent.top
                    property bool expanded:false

                    Column {
                      id:contents
                      spacing: 10
                      anchors.top: parent.top
                      anchors.bottom: parent.bottom
                      move: Transition {
                               NumberAnimation {
                                   properties: "y"
                                   duration: 250
                                   easing.type: Easing.OutBounce
                               }
                           }
                      add: Transition {
                          NumberAnimation {
                              properties: "opacity"
                              duration: 250
                              easing.type: Easing.OutBounce
                          }
                      }

                      Rectangle{
                          id: dateTimeBox
                          width: editList.width
                          height: 30
                          color: "Gray"
                          z:2

                          Text {
                              id:dateTimeTxt
                              text: qsTr("Date & time")
                              color:theme_fontColorNormal
                              font.pixelSize: theme_fontPixelSizeMedium
                              font.bold: true
                              width: parent.width
                              anchors.left: parent.left
                              anchors.leftMargin: 25
                              anchors.verticalCenter: parent.verticalCenter
                          }

                      }//end of dateTimeBox

                      Item {
                          id:dateTimeBlock
                          width: editList.innerBoxWidth
                          height:(allDayBlock.height+startTimeCmbBlock.height+finishTimeCmbBlock.height+5)
                          anchors.left: parent.left
                          anchors.leftMargin: 25
                          z:2

                          Column {
                              spacing: 3
                              y:0
                              move: Transition {
                                  NumberAnimation { properties: "y"; easing.type:Easing.OutBounce; duration:250 }
                              }

                              add: Transition {
                                  NumberAnimation { properties: "y"; easing.type:Easing.OutQuad; duration:250 }
                              }

                              Item {
                                  id:allDayBlock
                                  width:dateTimeBlock.width
                                  height: 50
                                  property bool allDay:allDayCheck.on

                                  Item {
                                      id: allDayTxtBox
                                      anchors.left:parent.left
                                      width:parent.width/3
                                      height: 30
                                      anchors.verticalCenter: parent.verticalCenter
                                      Text {
                                          id:allDayTxt
                                          text: qsTr("All-day")
                                          color:theme_fontColorNormal
                                          font.pixelSize: theme_fontPixelSizeMedium
                                          width:parent.width
                                          anchors.left: parent.left
                                          anchors.leftMargin: 5
                                          anchors.verticalCenter: parent.verticalCenter
                                          elide:Text.ElideRight
                                      }
                                  }

                                  ToggleButton {
                                      id: allDayCheck
                                      anchors.left:  allDayTxtBox.right
                                      anchors.verticalCenter: parent.verticalCenter
                                  }



                                  onAllDayChanged: {
                                        if(allDay) {
                                            container.allDaySet =  true;
                                            finishTimeBlock.opacity = 0;
                                            finishTimeBox.height = 0;
                                            finishTimeCmbBlock.opacity = 0;
                                            finishTimeCmbBlock.height=0;
                                            startTimeBox.opacity = 0;
                                            startTimeBox.height = 0;
                                        } else {
                                            container.allDaySet = false;
                                            finishTimeBlock.opacity = 1;
                                            finishTimeBox.height = 50;
                                            finishTimeCmbBlock.opacity = 1;
                                            finishTimeCmbBlock.height=50;
                                            startTimeBox.opacity = 1;
                                            startTimeBox.height = 50;

                                        }
                                  }

                              } //End alldayevent block

                              Row {
                                  Item{
                                      id:startTimeBlock
                                      width:dateTimeBlock.width/3
                                      height:50
                                      Text{
                                          id:startTxt
                                          text: qsTr("Start time")
                                          color:theme_fontColorNormal
                                          font.pixelSize: theme_fontPixelSizeMedium
                                          width:parent.width
                                          anchors.left: parent.left
                                          anchors.verticalCenter: parent.verticalCenter
                                          elide:Text.ElideRight
                                      }
                                  }//end starttimeblock

                                  Item {
                                      id:startTimeCmbBlock
                                      width:2*(dateTimeBlock.width/3)
                                      height:50
                                      Item{
                                          id:startDateBox
                                          height:50
                                          width: 2*(parent.width/3)-20
                                          anchors.left: parent.left
                                          anchors.verticalCenter: parent.verticalCenter                                          
                                          Button {
                                              id: startDateTxt
                                              anchors.fill:parent
                                              text: ""
                                              hasBackground: true
                                              bgSourceUp: "image://themedimage/widgets/common/button/button-dialogue"
                                              bgSourceDn: "image://themedimage/widgets/common/button/button-dialogue-active"
                                              font.pixelSize:theme_fontPixelSizeNormal
                                              textColor:theme_fontColorNormal
                                              onClicked: {
                                                  container.openDatePicker(1,window);
                                              }
                                          }
                                      }

                                      Item {
                                          id:startTimeBox
                                          anchors.right: parent.right
                                          anchors.left: startDateBox.right
                                          anchors.margins: 5
                                          anchors.verticalCenter: parent.verticalCenter
                                          height:50
                                          Button {
                                              id: startTimeTxt
                                              anchors.fill:parent
                                              text: ""
                                              hasBackground: true
                                              bgSourceUp: "image://themedimage/widgets/common/button/button-dialogue"
                                              bgSourceDn: "image://themedimage/widgets/common/button/button-dialogue-active"
                                              font.pixelSize:theme_fontPixelSizeNormal
                                              textColor:theme_fontColorNormal
                                              onClicked: {
                                                  container.openTimePicker(1,window);
                                              }
                                          }
                                      }
                                  }//end of startTimeCmbBlock
                              }//startrow

                              Row {
                                  Item{
                                      id:finishTimeBlock
                                      width:dateTimeBlock.width/3
                                      height:50
                                      Text{
                                          id:finishTxt
                                          text: qsTr("End time")
                                          color:theme_fontColorNormal
                                          font.pixelSize: theme_fontPixelSizeMedium
                                          width:parent.width
                                          anchors.left: parent.left
                                          anchors.verticalCenter: parent.verticalCenter
                                          elide:Text.ElideRight
                                      }
                                  }//end finishtimeblock (string val)

                                  Item {
                                      id:finishTimeCmbBlock
                                      width: 2*(dateTimeBlock.width/3)
                                      height:50

                                      Item{
                                          id:finishDateBox
                                          anchors.top: parent.top
                                          anchors.left: parent.left
                                          width: 2*(parent.width/3)-20
                                          height:parent.height
                                          Button {
                                              id: finishDateTxt
                                              anchors.fill:parent
                                              text: ""
                                              hasBackground: true
                                              bgSourceUp: "image://themedimage/widgets/common/button/button-dialogue"
                                              bgSourceDn: "image://themedimage/widgets/common/button/button-dialogue-active"
                                              font.pixelSize:theme_fontPixelSizeNormal
                                              textColor:theme_fontColorNormal
                                              onClicked: {
                                                  container.openDatePicker(2,window);
                                              }
                                          }

                                      }

                                      Item {
                                          id:finishTimeBox
                                          anchors.right: parent.right
                                          anchors.left: finishDateBox.right
                                          anchors.margins: 5
                                          anchors.verticalCenter: parent.verticalCenter
                                          height:50
                                          Button {
                                              id: finishTimeTxt
                                              anchors.fill:parent
                                              text: ""
                                              hasBackground: true
                                              bgSourceUp: "image://themedimage/widgets/common/button/button-dialogue"
                                              bgSourceDn: "image://themedimage/widgets/common/button/button-dialogue-active"
                                              font.pixelSize:theme_fontPixelSizeNormal
                                              textColor:theme_fontColorNormal
                                              onClicked: {
                                                  container.openTimePicker(2,window);
                                              }
                                          }
                                      }
                                  }//end of finishTimeCmbBlock

                              }//end finish row

                          }//end of column

                      }//end of datetimeblock


                      Item {
                          id: moreBlock
                          width: editList.width
                          height: 50
                          z:-2

                          Item{
                              id: moreButton
                              height: parent.height
                              width: parent.width
                              anchors.centerIn: parent
                              Image {
                                  id:moreSpacer1
                                  width: parent.width
                                  anchors.top: parent.top
                                  source: "image://themedimage/images/menu_item_separator"
                              }
                              Text {
                                  id:moreTxt
                                  text: qsTr("More")
                                  anchors.fill: parent
                                  horizontalAlignment: Text.AlignHCenter
                                  verticalAlignment: Text.AlignVCenter
                                  color:theme_fontColorHighlight
                                  font.pixelSize: theme_fontPixelSizeLarger
                              }
                              MouseArea {
                                  id:moreMouseArea
                                  anchors.fill:parent
                                  onClicked: {
                                      scrollableEditArea.interactive = true;
                                      moreButton.opacity=0;
                                      moreBlock.height=0;
                                      scrollableSection.expanded=true;
                                      editList.windowExpanded=true;
                                      scrollableEditArea.flickableExpanded=true;
                                  }
                              }
                              Behavior on opacity { NumberAnimation {} }
                              Image {
                                  id:moreSpacer2
                                  width: parent.width
                                  anchors.top: parent.bottom
                                  source: "image://themedimage/images/menu_item_separator"
                              }
                          }


                      }//More Button area

                      Item {
                          id: moreDetailsBlock
                          width: editList.width
                          height:moreContents.height
                          opacity: 0
                          z:-2
                          Column {
                              id:moreContents
                              spacing:5
                              y: 0
                              move: Transition {
                                ParallelAnimation {
                                NumberAnimation { properties: "y"; easing.type: Easing.OutQuad; duration:50 }
                                NumberAnimation { properties: "height";duration: 50; easing.type: Easing.OutQuad }
                                NumberAnimation { properties: "opacity";duration: 250; easing.type: Easing.OutQuad }
                                }
                              }
                              add: Transition {
                                  ParallelAnimation {
                                NumberAnimation { properties: "y"; easing.type: Easing.OutQuad; duration:50 }
                                NumberAnimation { properties: "height";duration: 50; easing.type: Easing.OutQuad }
                                NumberAnimation { properties: "opacity";duration: 250; easing.type: Easing.OutQuad }
                                  }
                              }


                              Row {
                                  anchors.left: parent.left
                                  anchors.leftMargin: 25
                                  Item{
                                      id:tzText
                                      width:dateTimeBlock.width/3
                                      height:50
                                      Text{
                                          id:tzTxt
                                          text: qsTr("Time zone")
                                          color:theme_fontColorNormal
                                          font.pixelSize:theme_fontPixelSizeMedium
                                          width:parent.width
                                          anchors.left: parent.left
                                          anchors.verticalCenter: parent.verticalCenter
                                          elide:Text.ElideRight
                                      }
                                  }//end of tztext block

                                  Item {
                                      id:tzCmbBlock
                                      width: 2*(dateTimeBlock.width/3)
                                      height:50

                                      Button {
                                          id: tzCmb
                                          anchors.fill: parent
                                          text: gmtName
                                          hasBackground: true
                                          bgSourceUp: "image://themedimage/widgets/common/button/button-dialogue"
                                          bgSourceDn: "image://themedimage/widgets/common/button/button-dialogue-active"
                                          font.pixelSize:theme_fontPixelSizeNormal
                                          textColor:theme_fontColorNormal
                                          property string gmtName: timezoneModel.getLocationName(clockModel.timezone)
                                          property string gmtTitle
                                          property int gmtOffset
                                          onClicked: {
                                              tzPicker.initLocation(clockModel.timezone);
                                              tzPicker.show();
                                          }
                                      }
                                  }//end of tzcmb block

                              }//end timezonerow

                              //Repeat Section
                              Rectangle{
                                  id: repeatTxtBox
                                  width: editList.width
                                  height: 30
                                  color: "Gray"
                                  Text {
                                      id:repeatTxt
                                      text: qsTr("Repeat")
                                      color:theme_fontColorNormal
                                      font.pixelSize:theme_fontPixelSizeMedium
                                      font.bold: true
                                      width: parent.width
                                      anchors.left: parent.left
                                      anchors.leftMargin: 25
                                      anchors.verticalCenter: parent.verticalCenter
                                  }

                              }//end of repeatTxtBox

                              Item {
                                  id:repeatCmbBlock
                                  width: editList.innerBoxWidth
                                  anchors.left: parent.left
                                  anchors.leftMargin: 25
                                  height:40
                                  property int repeatType:repeatCmb.selectedIndex
                                  DropDown {
                                      id: repeatCmb

                                      width: editList.innerBoxWidth
                                      anchors.fill: parent

                                      title: (windowType==UtilMethods.EAddEvent)?qsTr("Never"):utilities.getRepeatTypeString(container.repeatType)
                                      replaceDropDownTitle:true
                                      titleColor: "black"
                                      model: [  qsTr("Never"),
                                          qsTr("Every day"),
                                          qsTr("Every week") ,
                                          qsTr("Every 2 weeks"),
                                          qsTr("Every month"),
                                          qsTr("Every year"),
                                          //: Other kind of repeat interval
                                          qsTr("Other","Interval")
                                      ]
                                      payload: [ UtilMethods.ENoRepeat,UtilMethods.EEveryDay,UtilMethods.EEveryWeek,UtilMethods.EEvery2Weeks,UtilMethods.EEveryMonth,UtilMethods.EEveryYear,UtilMethods.EOtherRepeat ]
                                      onTriggered: {
                                          repeatCmbBlock.repeatType = payload[index];
                                      }
                                  }

                                  onRepeatTypeChanged: {
                                      if(repeatType != UtilMethods.ENoRepeat) {
                                          repeatEndCmbBlock.opacity=1;
                                          repeatEndCmbBlock.height = 40;
                                      } else {
                                          if(repeatType == UtilMethods.ENoRepeat) {
                                              if(repeatEndCmbBlock.opacity==1) {
                                                  repeatEndCmbBlock.opacity = 0;
                                                  repeatEndCmbBlock.height = 0;
                                              }
                                              if(repeatEndDateBox.opacity == 1) {
                                                  repeatEndDateBox.opacity = 0;
                                                  repeatEndDateBox.height = 0;
                                              }
                                          }
                                      }
                                  }

                              }//end of repeatCmbBlock block


                              Item {
                                  id:repeatEndCmbBlock
                                  anchors.left: parent.left
                                  anchors.leftMargin: 25
                                  width: editList.innerBoxWidth
                                  height:0
                                  opacity: 0
                                  Row {
                                      spacing: 10
                                      move: Transition {
                                               NumberAnimation { properties: "x"; easing.type:Easing.OutBounce; duration:250 }
                                       }

                                      Item {
                                          id: repeatEndComboBox
                                          width: repeatEndCmbBlock.width
                                          height: repeatEndCmbBlock.height
                                          property int repeatEndType:repeatEndCmb.selectedIndex

                                          DropDown {
                                              id: repeatEndCmb
                                              anchors.top: parent.top
                                              anchors.left: parent.left
                                              width: parent.width
                                              height:40
                                              replaceDropDownTitle:true
                                              titleColor: "black"
                                              model: [  qsTr("Repeats forever"), qsTr("Ends after number of times"), qsTr("Ends after date")]
                                              payload: [UtilMethods.EForever,UtilMethods.EForNTimes,UtilMethods.EAfterDate]
                                              onTriggered: {
                                                  repeatEndComboBox.repeatEndType = payload[index];
                                              }
                                          }

                                          onRepeatEndTypeChanged: {
                                              if(repeatEndType == UtilMethods.EForNTimes) {
                                                  repeatEndComboBox.width = repeatEndCmbBlock.width -50;
                                                  repeatCountBox.opacity = 1;
                                                  repeatCountBox.height= 30;
                                                  repeatCountBox.width = 40;
                                                  if(repeatEndDateBox.opacity==1) {
                                                      repeatEndDateBox.opacity = 0;
                                                      repeatEndDateBox.height = 0;
                                                  }
                                              } if(repeatEndType == UtilMethods.EAfterDate) {
                                                  repeatEndComboBox.width = repeatEndCmbBlock.width;
                                                  repeatEndDateBox.opacity = 1;
                                                  repeatEndDateBox.height = 50;
                                                  container.setEndRepeatDateValues();
                                                  if(repeatCountBox.opacity==1) {
                                                      repeatCountBox.opacity = 0;
                                                      repeatCountBox.height = 0;
                                                      repeatCountBox.width = 0;
                                                  }
                                              } else if(repeatEndType == UtilMethods.EForever){
                                                  repeatEndComboBox.width = repeatEndCmbBlock.width;
                                                  repeatEndDateBox.height = 0;
                                                  repeatEndDateBox.opacity = 0;
                                                  repeatCountBox.height = 0;
                                                  repeatCountBox.opacity = 0;
                                              }

                                          }
                                      }//end repeatendcmbbox

                                      Item {
                                          id: repeatCountBox
                                          height: 0
                                          width:0
                                          opacity:0
                                          TextEntry {
                                              id:repeatCountText
                                              anchors.fill: parent
                                              defaultText:"0"
                                              inputMethodHints:Qt.ImhDigitsOnly
                                              font.pixelSize:theme_fontPixelSizeMedium
                                              validator: IntValidator{bottom: 0;}
                                          }                                          
                                      }
                                  }//end row

                              }//repeatEndCmbBlock


                              Item {
                                  id: repeatEndDateBox
                                  width: editList.innerBoxWidth
                                  anchors.left: parent.left
                                  anchors.leftMargin: 25
                                  height:0
                                  opacity: 0
                                  Row {
                                      spacing: 5
                                      Item {
                                          id: endRepeatDayBox
                                          height: repeatEndDateBox.height
                                          width:2*(repeatEndDateBox.width/3)
                                          Button {
                                              id: endRepeatDayText
                                              anchors.fill:parent
                                              text: ""
                                              hasBackground: true
                                              bgSourceUp: "image://themedimage/widgets/common/button/button-dialogue"
                                              bgSourceDn: "image://themedimage/widgets/common/button/button-dialogue-active"
                                              font.pixelSize:theme_fontPixelSizeNormal
                                              textColor:theme_fontColorNormal
                                          }
                                      }//end repeatendday

                                      Item {
                                          id: endRepeatIconBox
                                          height: 50
                                          width:50
                                          Image {
                                                id: endDatePicker
                                                anchors.fill: parent
                                                source: "image://themedimage/images/calendar/icn_monthcalendar_up"
                                          }
                                          MouseArea {
                                              anchors.fill: parent
                                              onClicked: {
                                                   container.openDatePicker(3,window);
                                              }
                                          }
                                      }//end repeatend icon

                                  }//end of row
                              }//end of end repear date box


                              //Reminders Section
                              Rectangle{
                                  id: alarmTxtBox
                                  width: editList.width
                                  height: 30
                                  color: "Gray"
                                  Text {
                                      id:alarmTxt
                                      text: qsTr("Reminders")
                                      color:theme_fontColorNormal
                                      font.pixelSize: theme_fontPixelSizeMedium
                                      font.bold: true
                                      width: parent.width
                                      anchors.left: parent.left
                                      anchors.leftMargin: 25
                                      anchors.verticalCenter: parent.verticalCenter
                                  }

                              }//end of repeatTxtBox


                              Item{
                                  id:alarmCmbBlock
                                  width: editList.innerBoxWidth
                                  anchors.left: parent.left
                                  anchors.leftMargin: 25
                                  height:40
                                  DropDown {
                                      id: alarmCmb
                                      anchors.top: parent.top
                                      anchors.left: parent.left
                                      width: (parent.width)
                                      height:40
                                      title: (windowType==UtilMethods.EAddEvent)?qsTr("No reminder"):utilities.getAlarmString(container.alarmType)
                                      replaceDropDownTitle:true
                                      titleColor: "black"

                                      model: [  qsTr("No reminder"),
                                          qsTr("10 minutes before"),
                                          qsTr("15 minutes before"),
                                          qsTr("30 minutes before"),
                                          qsTr("1 hour before"),
                                          qsTr("2 hours before"),
                                          qsTr("1 day before"),
                                          qsTr("2 days before"),
                                          qsTr("1 week before"),
                                          //: Other type of alarm
                                          qsTr("Other","Alarm")
                                      ]
                                      payload: [UtilMethods.ENoAlarm,UtilMethods.E10MinB4,UtilMethods.E15MinB4,UtilMethods.E30MinB4,UtilMethods.E1HrB4,UtilMethods.E2HrsB4,UtilMethods.E1DayB4,UtilMethods.E2DaysB4,UtilMethods.E1WeekB4,UtilMethods.EOtherAlarm]
                                      onTriggered: {
                                          selectedIndex = payload[index];
                                      }
                                  }

                                  Image {
                                       id: cancelAlarmIcon
                                       source: "image://themedimage/images/icn_close_dn"
                                       anchors.right: parent.right
                                       height: 0
                                       width:0
                                       property bool pressed: false
                                       states: [
                                           State {
                                               name: "pressed"
                                               when: cancelAlarmIcon.pressed
                                               PropertyChanges {
                                                   target: cancelAlarmIcon
                                                   source: "image://themedimage/images/icn_close_up"
                                               }
                                           }
                                       ]
                                       MouseArea {
                                           anchors.fill: parent
                                           onPressed: cancelAlarmIcon.pressed = true
                                           onReleased: cancelAlarmIcon.pressed = false
                                           onClicked: {

                                           }
                                       }
                                   }
                              }//end of alarmCmbBox

                              //Location Section
                              Rectangle{
                                  id: locTxtBox
                                  width: editList.width
                                  height: 30
                                  anchors.left: parent.left
                                  color: "Gray"
                                  Text {
                                      id:locTxt
                                      text: qsTr("Location")
                                      color:theme_fontColorNormal
                                      font.pixelSize: theme_fontPixelSizeMedium
                                      font.bold: true
                                      width: parent.width
                                      anchors.left: parent.left
                                      anchors.leftMargin: 25
                                      anchors.verticalCenter: parent.verticalCenter
                                  }

                              }//end of locTxtBox

                              Item {
                                  id:locInputBlock
                                  width: editList.innerBoxWidth
                                  anchors.left: parent.left
                                  anchors.leftMargin: 25
                                  height:100
                                  Item {
                                      id: locInnerArea
                                      width:parent.width
                                      height:parent.height
                                      anchors.top: parent.top
                                      clip:true
                                      Item {
                                          id:locInputBox
                                          height: 100
                                          width:editList.innerBoxWidth
                                          TextField {
                                              id: locInputText
                                              text: ""
                                              anchors.fill:parent
                                          }
                                      }


                                  }//end location flickable

                              }//end of locInputBlock

                              //Notes Section
                              Rectangle{
                                  id: notesTxtBox
                                  width: editList.width
                                  height: 30
                                  anchors.left: parent.left
                                  color: "Gray"
                                  Text {
                                      id:notesTxt
                                      text: qsTr("Notes")
                                      color:theme_fontColorNormal
                                      font.pixelSize:theme_fontPixelSizeMedium
                                      font.bold: true
                                      width: parent.width
                                      anchors.left: parent.left
                                      anchors.leftMargin: 25
                                      anchors.verticalCenter: parent.verticalCenter
                                  }

                              }//end of notesTxtBox

                              Item {
                                  id:notesBlock
                                  anchors.left: parent.left
                                  anchors.leftMargin: 25
                                  width: editList.innerBoxWidth
                                  height:150
                                  Item{
                                      id:notesArea
                                      height: 150
                                      width:editList.innerBoxWidth
                                      clip: true
                                      anchors.top: notesBlock.top
                                      Item {
                                          id:notesInputBlock
                                          anchors.fill:parent
                                          width: editList.innerBoxWidth
                                          height:150

                                          TextField {
                                              id: notesInputText
                                              text: ""
                                              anchors.fill:parent
                                          }
                                      }//end of notesInputBlock

                                  }//end of flickable

                              }//end of notesBlock


                              //Delete Event block
                              Item {
                                  id:deleteButtonBox
                                  height:50
                                  width:editList.innerBoxWidth
                                  anchors.left: parent.left
                                  anchors.leftMargin: 25
                                  Button {
                                      id: deleteButton
                                      height:(windowType==UtilMethods.EAddEvent)?0:50
                                      anchors.horizontalCenter: parent.horizontalCenter
                                      text: qsTr("Delete event")
                                      opacity: (windowType==UtilMethods.EAddEvent)?0:1
                                      hasBackground: true
                                      bgSourceUp: "image://themedimage/widgets/common/button/button"
                                      bgSourceDn: "image://themedimage/widgets/common/button/button-pressed"
                                      onClicked: {
                                          window.deleteEvent(container.uid);
                                          outer.hide();
                                          outer.close();
                                      }
                                  }

                              }//end of deleteButton

                          }//end of inner column

                          states: [
                              State {
                                  name: "expanded"
                                  PropertyChanges { target: moreDetailsBlock; height:moreContents.height; }
                                  PropertyChanges { target: moreDetailsBlock; visible: true; opacity: 1.0 }
                                  when: (scrollableSection.expanded==true)
                              }
                          ]
                          transitions: [
                              Transition {
                                 ParallelAnimation {
                                      NumberAnimation {
                                          properties: "height"
                                          duration: 50
                                          easing.type: Easing.OutQuad
                                      }
                                      NumberAnimation {
                                          properties: "opacity"
                                          duration: 50
                                          easing.type: Easing.InCubic
                                      }
                                  }
                              }
                          ]


                      }


                    }//end of column

                }//end scrollable edit area
                states: [
                    State {
                        name: "flickableExpanded"
                        PropertyChanges { target: scrollableEditArea; height:editList.height;}
                        when: (scrollableEditArea.flickableExpanded==true)
                    }
                ]
                transitions: [
                    Transition {
                       SequentialAnimation {
                            NumberAnimation {
                                properties: "height"
                                duration: 50
                                easing.type: Easing.OutQuad
                            }

                        }
                    }
                ]
            }//end of flickable

            states: [
                State {
                    name: "windowExpanded"
                    PropertyChanges {
                        target: container;
                        height:{
                            topItem.calcTopParent();
                            if(window.inLandscape || window.inInvertedLandscape) {
                                return 2*(topItem.topHeight/3);
                            }
                            else {
                                return 2*(topItem.topHeight)/3;
                            }
                        }
                    }
                    PropertyChanges { target: scrollableSection; height:900;}
                    PropertyChanges { target: scrollableEditArea; height:editList.height;}
                    when: (editList.windowExpanded==true)
                }
            ]
            transitions: [
                Transition {
                   SequentialAnimation {
                        NumberAnimation {
                            properties: "height"
                            duration: 500
                            easing.type: Easing.OutQuad
                        }

                    }
                }
            ]

        } //end of rectangle


    } //end of Item

    buttonRow: [
        //Save and Cancel buttons
        Button {
            id: saveButton
            height: parent.height
            bgSourceUp: "image://themedimage/widgets/common/button/button-default"
            bgSourceDn: "image://themedimage/widgets/common/button/button-default-pressed"
            text: qsTr("Save")
            hasBackground: true
            onClicked: {
                if(container.validateInputs()) {
                    container.createIOObject();
                    outer.hide();
                    outer.close();
                }
            }
        },

        Button {
            id: cancelButton
            height: parent.height
            bgSourceUp: "image://themedimage/widgets/common/button/button"
            bgSourceDn: "image://themedimage/widgets/common/button/button-pressed"
            text: qsTr("Cancel")
            hasBackground: true
            onClicked: {
                outer.hide();
                outer.close();
            }
        }
    ]

}

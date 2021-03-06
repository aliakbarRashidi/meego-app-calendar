/*
 * Copyright 2011 Intel Corporation.
 *
 * This program is licensed under the terms and conditions of the
 * Apache License, version 2.0.  The full text of the Apache License is at 	
 * http://www.apache.org/licenses/LICENSE-2.0
 */

import Qt 4.7
import MeeGo.App.Calendar 0.1
import MeeGo.Components 0.1
import MeeGo.Labs.Components 0.1 as Labs
import Qt.labs.gestures 2.0

AppPage {
    id: centerPane
    pageTitle: qsTr("Day")
    property int offset:0
    property date dateInFocus:initDate()
    property string dateInFocusVal
    property int currDayIndex:0    
    property int allDayEventsCount:allDayViewModel.count
    property int xVal:0
    property int yVal:0
    actionMenuModel:  [ qsTr("Create new event"), qsTr("Go to today"), qsTr("Go to date")]
    actionMenuPayload: [0,1,2]
    allowActionMenuSignal: true
    onActionMenuIconClicked: {
        xVal = mouseX;
        yVal = mouseY;
    }
    onActionMenuTriggered: {
        switch (selectedItem) {
            case 0: {
                window.openNewEventView(xVal,yVal,false);
                break;
            }
            case 1: {
                window.gotoToday=true;
                break;
            }
            case 2: {
                window.openDatePicker();
                break;
            }
        }
    }

    CalendarController {
        id:controller
    }

    Connections {
        target:controller
        onDbLoaded: {
            initDate();
        }

        onDbChanged: {
            console.log("Inside CalendarDayView Connections: Received dbChnaged signal, updating view");
            initDate();
        }
    }


    function initDate()
    {
        dateInFocus = window.appDateInFocus;
        dateInFocusVal = i18nHelper.localDate(dateInFocus, Labs.LocaleHelper.DateFull);
        resetCalendarDayModels(dateInFocus);
    }


    Connections {
        target:window
        onGotoDateChanged: {
            if(window.gotoDate) {
                dateInFocus =  window.dateFromOutside;
                window.appDateInFocus = dateInFocus;
                daysModel.loadGivenWeekValuesFromDate(dateInFocus)
                allDayViewModel.loadGivenDayModel(dateInFocus);
                allDayEventsCount = allDayViewModel.count;
                timeListModel.loadGivenDayModel(dateInFocus);
                dateInFocusVal = i18nHelper.localDate(dateInFocus, Labs.LocaleHelper.DateFull);
                timeListView.positionViewAtIndex(window.positionOfView,ListView.Beginning);
                window.gotoDate=false;
            }
        }

        onGotoTodayChanged: {
            if(window.gotoToday) {
                window.appDateInFocus = utilities.getCurrentDateVal();
                initDate();
                daysModel.loadGivenWeekValuesFromDate(dateInFocus);
                allDayViewModel.loadGivenDayModel(dateInFocus);
                allDayEventsCount = allDayViewModel.count;
                timeListModel.loadGivenDayModel(dateInFocus);
                timeListView.positionViewAtIndex(window.positionOfView,ListView.Beginning);
                window.gotoToday=false;
            }
        }

        onAddedEventChanged: {
            if(window.addedEvent) {
                allDayViewModel.loadGivenDayModel(dateInFocus);
                allDayEventsCount = allDayViewModel.count;
                timeListModel.loadGivenDayModel(dateInFocus);
                timeListView.positionViewAtIndex(window.positionOfView,ListView.Beginning);
                window.addedEvent = false;
            }
        }

        onDeletedEventChanged: {
            if(window.deletedEvent) {
                allDayViewModel.loadGivenDayModel(dateInFocus);
                allDayEventsCount = allDayViewModel.count;
                timeListModel.loadGivenDayModel(dateInFocus);
                timeListView.positionViewAtIndex(window.positionOfView,ListView.Beginning);
                window.deletedEvent = false;
            }
        }

        onTriggeredExternallyChanged: {
            if(window.triggeredExternally) {
                dateInFocus =  window.dateFromOutside;
                window.appDateInFocus = dateInFocus;
                dateInFocusVal = i18nHelper.localDate(dateInFocus, Labs.LocaleHelper.DateFull);
                daysModel.loadGivenWeekValuesFromDate(dateInFocus)
                allDayViewModel.loadGivenDayModel(dateInFocus);
                allDayEventsCount = allDayViewModel.count;
                timeListModel.loadGivenDayModel(dateInFocus);
                timeListView.positionViewAtIndex(window.positionOfView,ListView.Beginning);
                window.triggeredExternally = false;
            }
        }
    }


    function resetCalendarDayModels(coreDateVal) {
        allDayViewModel.loadGivenDayModel(coreDateVal);
        daysModel.loadGivenWeekValuesFromDate(coreDateVal);
        allDayEventsCount = allDayViewModel.count;
        timeListModel.loadGivenDayModel(coreDateVal);
        dateInFocus = coreDateVal;
        window.appDateInFocus = dateInFocus;
        dateInFocusVal = i18nHelper.localDate(dateInFocus, Labs.LocaleHelper.DateFull);
        timeListView.positionViewAtIndex(window.positionOfView,ListView.Beginning);
    }

    function resetFocus(offset)
    {
        dateInFocus = utilities.addDMYToGivenDate(dateInFocus,(offset),0,0);
        window.appDateInFocus = dateInFocus;
        resetCalendarDayModels(dateInFocus);
    }

    function isDateInFocus(coreDateVal)
    {
       return utilities.datesEqual(coreDateVal,dateInFocus);
    }

    function isCurrentDate(coreDateVal,index)
    {
        var now = new Date();
        var refDate = new Date(utilities.getLongDate(coreDateVal))
        if((now.getDate()==refDate.getDate()) && (now.getMonth()==refDate.getMonth()) && (now.getFullYear()==refDate.getFullYear())) {
            currDayIndex = index;
            return true;
        } else {
            return false;
        }
    }

    function displayContextMenu(xVal,yVal,uid,component,loader,popUpParent,description,summary,location,alarmType,repeatString,startDate,startTime,endTime,zoneOffset,zoneName,allDay)
    {
        loader.sourceComponent = component
        loader.item.parent = popUpParent
        loader.item.mapX = xVal;
        loader.item.mapY = yVal;
        loader.item.eventId = uid;
        loader.item.description = description;
        loader.item.summary = summary;
        loader.item.location = location;
        loader.item.alarmType = alarmType;
        loader.item.repeatText = repeatString;
        loader.item.zoneOffset = zoneOffset;
        loader.item.zoneName = zoneName;
        loader.item.startDate = startDate;
        loader.item.startTime = startTime;
        loader.item.endTime = endTime;
        loader.item.allDay = allDay;
        loader.item.initMaps();
    }

    Loader {
        id:popUpLoader
    }

    Component {
        id: eventActionsPopup
        EventActionsPopup {
            onClose: {
                popUpLoader.sourceComponent = undefined;
            }
        }
    }

    Labs.LocaleHelper {
        id:i18nHelper
    }

    UtilMethods {
        id: utilities
    }

    CalendarWeekModel {
        id:daysModel
        weekStartDay:i18nHelper.defaultFirstDayOfWeek
        dayInFocus:window.appDateInFocus
    }

    TimeListModel {
        id:timeListModel
        dateVal:dateInFocus
    }

    DayViewModel {
        id:allDayViewModel
        modelType:UtilMethods.EAllDay
        dateVal:dateInFocus
        Component.onCompleted: {
            centerPane.allDayEventsCount = allDayViewModel.count;
        }
    }

    TopItem {
        id:dayViewTopItem
    }

    Column {
        id: dayViewData
        spacing: 2
        anchors.fill:parent

        HeaderComponentView {
            id:navHeader
            width: dayViewTopItem.topWidth
            height: 50
            dateVal: dateInFocusVal
            onNextTriggered: {
                daysModel.loadGivenWeekValuesFromOffset(dateInFocus,1);
                resetFocus(1);
            }
            onPrevTriggered: {
                daysModel.loadGivenWeekValuesFromOffset(dateInFocus,-1);
                resetFocus(-1);
            }
        }

        ThemeImage {
            id: spacerImage
            height:dayViewTopItem.topHeight - (navHeader.height)
            width: dayViewTopItem.topWidth
            source: "image://themedimage/images/titlebar_l"

            Rectangle {
                id: calData
                height:dayViewTopItem.topHeight - (navHeader.height)-20
                width: dayViewTopItem.topWidth-20
                anchors.centerIn: parent
                color: "lightgray"
                border.width:2
                border.color: "gray"

                Column {
                    id:stacker

                    Item {
                        id:dayBox
                        width:calData.width
                        height:100
                        Row {
                            id:dayRow
                            anchors.horizontalCenter: dayBox.horizontalCenter
                            anchors.top: dayBox.top

                            Repeater {
                                id: dayRepeater
                                property int dayIndex:0
                                property int prevIndex:0
                                model: daysModel
                                Rectangle {
                                    id:dateValBox
                                    width:dayBox.width/(7)
                                    height: 40
                                    border.width:2
                                    border.color: (isDateInFocus(coreDateVal))?"white":"gray"
                                    color:"transparent"
                                    ThemeImage {
                                        id:dateBgImage
                                        source:(isDateInFocus(coreDateVal))? "image://themedimage/widgets/apps/calendar/calendar":"image://themedimage/widgets/apps/calendar/weekday"
                                        anchors.top:parent.top
                                        anchors.bottom:parent.bottom
                                        anchors.left:parent.left
                                        anchors.right:parent.right
                                        anchors.margins:1
                                    }

                                    Text {
                                          id: dateValTxt
                                          text:i18nHelper.localDate(coreDateVal,Labs.LocaleHelper.DateWeekdayDayShort)
                                          color:isCurrentDate(coreDateVal,index)?theme_buttonFontColorActive:theme_fontColorNormal
                                          font.pixelSize: (window.inLandscape)?theme_fontPixelSizeLarge:theme_fontPixelSizeMedium
                                          anchors.verticalCenter: parent.verticalCenter
                                          anchors.horizontalCenter: parent.horizontalCenter
                                          elide: Text.ElideRight
                                     }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            resetCalendarDayModels(coreDateVal);
                                            if (centerContent.state == "EXPAND"){
                                                centerContent.state = "NORMAL"
                                                allDayBox.height = 60
                                                allDayIcon.source="image://themedimage/images/popupbox_arrow_bottom";
                                            }
                                        }
                                    }
                                }

                            }//end of repeater
                        }//end of Row

                        Rectangle {
                            id: allDayBox
                            height: 60
                            width:calData.width
                            anchors.top:dayRow.bottom
                            color:"white"
                             Row {
                                 id:allDayRow
                                 anchors.top: allDayBox.top
                                 anchors.left: allDayBox.left
                                 anchors.margins: 10
                                 Item {
                                     id: allDayTextIconBox
                                     height:allDayBox.height
                                     width: allDayText.width+allDayIconBox.width
                                     z:1

                                     Item {
                                         id:allDayTextBox
                                         width:allDayText.width
                                         height: 30
                                         anchors.top: allDayTextIconBox.top
                                         Text {
                                             id: allDayText
                                             text: qsTr("All day")
                                             font.bold: true
                                             color:theme_fontColorNormal
                                             font.pixelSize: (window.inLandscape)?theme_fontPixelSizeMedium:theme_fontPixelSizeSmall
                                             elide: Text.ElideRight
                                         }
                                     }//end alldaytextbox

                                     Item {
                                         id: allDayIconBox
                                         height:20
                                         width:30
                                         anchors.bottom: allDayTextIconBox.bottom
                                         anchors.bottomMargin: 5
                                         anchors.horizontalCenter: parent.horizontalCenter
                                         visible:(allDayEventsCount>1)?1:0
                                         z:500
                                         ThemeImage {
                                             id:allDayIcon
                                             source:"image://themedimage/images/popupbox_arrow_bottom"
                                             anchors.fill: parent
                                         }

                                         MouseArea {
                                             id: allDayEventExpandIcon
                                             anchors.fill: parent
                                             onClicked: {
                                                 allDayIcon.source="";
                                                 allDayBox.height=100;
                                                 centerContent.state="EXPAND";
                                             }
                                         }
                                     }//end of alldayiconbox
                                     ExtendedMouseArea {
                                         anchors.fill: parent
                                         onClicked: {
                                             dayViewTopItem.calcTopParent();
                                             var map = mapToItem (dayViewTopItem.topItem, mouseX, mouseY);
                                             window.openNewEventView(map.x,map.y,true);
                                         }
                                     }
                                 }//allDayTextIconBox

                                 //Display the all day events here
                                 Item {
                                    id: allDayEventsDisplayBox
                                    height:allDayBox.height
                                    width: allDayBox.width-allDayTextIconBox.width-2*allDayRow.anchors.margins
                                    z:1

                                    Item {
                                        id:allDayDisplayBox
                                        height:(allDayEventsCount>0)?(parent.height-5):0
                                        width: parent.width-20
                                        anchors.centerIn:parent
                                        z:500
                                        ListView {
                                            id:allDayView
                                            anchors.fill: parent
                                            clip: true
                                            model: allDayViewModel
                                            spacing: 3
                                            delegate: Item {
                                                id: calItemBox
                                                height: 30
                                                width: allDayDisplayBox.width
                                                ThemeImage {
                                                     id:allDayImage
                                                     source:"image://themedimage/widgets/apps/calendar/event-allday"
                                                     anchors.fill: parent
                                                     Item {
                                                         id: allDayDescBox
                                                         height: parent.height
                                                         width:parent.width
                                                         anchors.top: parent.top
                                                         Text {
                                                             id: allDayDescText
                                                             //: %n corresponds to Events count
                                                             text: (index==2 && (allDayViewModel.count>3))?qsTr("%n more event(s) exist", "", allDayViewModel.count-2):summary
                                                             anchors.left: parent.left
                                                             anchors.leftMargin: 20
                                                             anchors.verticalCenter: parent.verticalCenter
                                                             color:theme_fontColorNormal
                                                             font.pixelSize:theme_fontPixelSizeMedium
                                                             width:allDayDescBox.width
                                                             elide: Text.ElideRight
                                                         }
                                                     }//end allDayDescBox

                                                     ExtendedMouseArea {
                                                          anchors.fill:parent
                                                          onPressedAndMoved: {
                                                               allDayDescText.text = summary;
                                                          }

                                                          onClicked: {
                                                              allDayDescBox.focus = true;
                                                              if(index ==2 && (allDayViewModel.count>3)) {
                                                                  allDayDescText.text = summary;
                                                              }
                                                              var map = mapToItem (dayViewTopItem.topItem, mouseX, mouseY);
                                                              window.openView (map.x,map.y,uid,description,summary,location,alarmType,utilities.getRepeatTypeString(repeatType),startDate,startTime,endTime,zoneOffset,zoneName,allDay,false,false);

                                                          }
                                                          onLongPressAndHold: {
                                                              var map = mapToItem (dayViewTopItem.topItem, mouseX, mouseY);
                                                              displayContextMenu (map.x, map.y,uid,eventActionsPopup,popUpLoader,allDayImage,description,summary,location,alarmType,utilities.getRepeatTypeString(repeatType),startDate,startTime,endTime,zoneOffset,zoneName,allDay);
                                                          }

                                                  }//ExtendedMouseArea

                                                }

                                            }
                                        }
                                    }
                                    ExtendedMouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            dayViewTopItem.calcTopParent();
                                            var map = mapToItem (dayViewTopItem.topItem, mouseX, mouseY);
                                            window.openNewEventView(map.x,map.y,true);
                                        }
                                    }

                                 }//end alldayeventsdisplaybox
                             }

                         }//end of alldaybox


                    }//end of dayBox


                    Image {
                        id:headerDivider
                        width: calData.width
                        //source: "image://themedimage/images/menu_item_separator"
                    } //end of headerDivider

                    Rectangle {
                         id: centerContent
                         height: calData.height-dayBox.height-80
                         width: calData.width
                         border.width:2
                         border.color: "gray"
                         color:"white"
                         states: [
                             State {
                                 name: "EXPAND"
                                 //when: allDayEventExpandIcon.pressed
                                 PropertyChanges {
                                    target: centerContent
                                    y: dayBox.height+allDayBox.height-60
                                 }
                             },
                             State {
                                 name: "NORMAL"
                                 //when: allDayEventExpandIcon.pressed
                                 PropertyChanges {
                                    target: centerContent
                                    y: dayBox.height
                                 }
                             }
                         ]
                         transitions:[
                              Transition {
                                  to: "EXPAND"
                                  NumberAnimation {
                                      properties: "y"
                                      easing.type: Easing.OutQunit
                                  }
                             }
                         ]

                         ListView {
                             id: timeListView
                             anchors.fill: parent
                             clip: true
                             model:timeListModel
                             contentHeight:(timeListModel.count+2)*(50)
                             contentWidth: timeListView.width
                             cacheBuffer: (timeListModel.count+2)*50-timeListView.height // Set cacheBuffer to remain the scroll area content.
                             z:1
                             focus: true
                             boundsBehavior: Flickable.StopAtBounds

                             delegate: Item {
                                         id: calTimeValBox
                                         height: 50
                                         width: centerContent.width
                                         z:-model.index
                                         Rectangle {
                                             id: timeValBox
                                             height: parent.height
                                             width:calData.width/12
                                             color: "transparent"
                                             anchors.left: parent.left
                                             border.width:2
                                             border.color: "lightgray"

                                             Text {
                                                 id: timeValText
                                                 text:(index%2==0)?i18nHelper.localTime(timeVal, Labs.LocaleHelper.TimeFull):""
                                                 anchors.top:parent.top
                                                 anchors.horizontalCenter:parent.horizontalCenter
                                                 font.bold: true
                                                 color:theme_fontColorNormal
                                                 font.pixelSize: (window.inLandscape)?theme_fontPixelSizeMedium:theme_fontPixelSizeSmall
                                                 elide: Text.ElideRight
                                             }
                                         }//end timeValBox
                                         Rectangle {
                                             id: vacantAreaBox
                                             height: parent.height
                                             width: parent.width-timeValBox.width
                                             anchors.left: timeValBox.right
                                             color:"transparent"
                                             border.width:2
                                             border.color: "lightgray"
                                             property int parentIndex:index
                                             z:2

                                             Repeater {
                                                 id:calDataItemsList
                                                 model: dataModel
                                                 focus: true
                                                 delegate:Item {
                                                     id: displayRect
                                                     height: (heightUnits*vacantAreaBox.height)
                                                     width: 9*(widthUnits*vacantAreaBox.width)/10
                                                     x:(xUnits+xUnits*displayRect.width)+5
                                                     ThemeImage {
                                                         id:regEventImage
                                                         source:"image://themedimage/widgets/apps/calendar/event"
                                                         anchors.fill: parent
                                                         z:1000
                                                         Item {
                                                             id:descriptionBox
                                                             width: 8*(displayRect.width/9)
                                                             height:displayRect.height
                                                             anchors.left: parent.left
                                                             anchors.leftMargin: 5
                                                             Column {
                                                                 spacing: 2
                                                                 anchors.top: parent.top
                                                                 anchors.topMargin: 3
                                                                 anchors.leftMargin: 3
                                                                 Text {
                                                                       id: eventDescription
                                                                       text:summary
                                                                       font.bold: true
                                                                       color:theme_fontColorNormal
                                                                       font.pixelSize: theme_fontPixelSizeMedium
                                                                       width: descriptionBox.width
                                                                       elide: Text.ElideRight
                                                                  }

                                                                 Text {
                                                                       id: eventTime
                                                                       //: This is time range ("StartTime - EndTime") %1 is StartTime and %2 is EndTime
                                                                       text: qsTr("%1 - %2","TimeRange").arg(i18nHelper.localTime(startTime, Labs.LocaleHelper.TimeFull)).arg(i18nHelper.localTime(endTime, Labs.LocaleHelper.TimeFull));
                                                                       color:theme_fontColorNormal
                                                                       width: descriptionBox.width
                                                                       font.pixelSize:theme_fontPixelSizeMedium
                                                                       elide: Text.ElideRight
                                                                  }
                                                             }
                                                         }

                                                         ExtendedMouseArea {
                                                             anchors.fill: parent
                                                             onClicked: {
                                                                 var map = mapToItem (dayViewTopItem.topItem, mouseX, mouseY);
                                                                 window.openView (map.x,map.y,uid,description,summary,location,alarmType,utilities.getRepeatTypeString(repeatType),startDate,startTime,endTime,zoneOffset,zoneName,allDay,false,false)
                                                             }
                                                             onLongPressAndHold: {
                                                                 var map = mapToItem (dayViewTopItem.topItem, mouseX, mouseY);
                                                                 displayContextMenu (map.x, map.y,uid,eventActionsPopup,popUpLoader,regEventImage,description,summary,location,alarmType,utilities.getRepeatTypeString(repeatType),startDate,startTime,endTime,zoneOffset,zoneName,allDay);
                                                             }
                                                         }
                                                     }
                                                 }
                                             }//end repeater

                                         }//Inner rectangle with delegate to view the cal events


                                         GestureArea {
                                             anchors.fill: parent

                                            Swipe {
                                                 onFinished: {
                                                      if(gesture.horizontalDirection == 1)  { //QSwipeGesture::Right
                                                          daysModel.loadGivenWeekValuesFromOffset(dateInFocus,1);
                                                          resetFocus(1);
                                                      } else if(gesture.horizontalDirection == 2)  { //QSwipeGesture::Left
                                                          daysModel.loadGivenWeekValuesFromOffset(dateInFocus,-1);
                                                          resetFocus(-1);
                                                      }
                                                 }
                                             }
                                         }//end GestureArea


                                         ExtendedMouseArea {
                                             anchors.fill: parent
                                             onClicked: {
                                                 window.eventStartHr=startHr;
                                                 window.eventEndHr=endHr;
                                                 dayViewTopItem.calcTopParent();
                                                 var map = mapToItem (dayViewTopItem.topItem, mouseX, mouseY);
                                                 window.openNewEventView(map.x,map.y,false);
                                             }
                                             onLongPressAndHold: {
                                                 window.eventStartHr=startHr;
                                                 window.eventEndHr=endHr;
                                                 dayViewTopItem.calcTopParent();
                                                 var map = mapToItem (dayViewTopItem.topItem, mouseX, mouseY);
                                                 window.openNewEventView(map.x,map.y,false);
                                             }
                                         }

                                     }//end calTimeValBox

                             Component.onCompleted: {
                                 timeListView.positionViewAtIndex(window.positionOfView,ListView.Beginning);
                                 window.positionOfView = UtilMethods.EDayTimeStart;
                             }


                         }

                     }//end centerContent

                }//end of Column inside calData


            }//end of calData

        }//end of spacerImage
    }//end of top column
}

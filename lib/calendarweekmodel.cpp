/*
 * Copyright 2011 Intel Corporation.
 *
 * This program is licensed under the terms and conditions of the
 * Apache License, version 2.0.  The full text of the Apache License is at 	
 * http://www.apache.org/licenses/LICENSE-2.0
 */

#include "calendarweekmodel.h"
#include <inttypes.h>
#include <utilmethods.h>

DateItem::DateItem(int index, QString dateValString, QDate coreDateVal, QObject *parent) : QObject(parent)
{
    this->index = index;
    this->dateValString = dateValString;
    this->coreDateVal = coreDateVal;
}


CalendarWeekModel::CalendarWeekModel(QObject *parent) : QAbstractListModel(parent)
{
    QHash<int, QByteArray> roles;
    roles.insert(DateItem::Index, "index");
    roles.insert(DateItem::DateValString, "dateValString");
    roles.insert(DateItem::CoreDateVal, "coreDateVal");
    setRoleNames(roles);
    //loadCurrentWeekValues();
}

CalendarWeekModel::~CalendarWeekModel()
{
    clearData();
}

void CalendarWeekModel::loadCurrentWeekValues()
{
    UtilMethods utilities;
    QDate currentDate = dayInFocus;
    int dayOfWeek = currentDate.dayOfWeek();
    int daysBeforeStartDay = (7-weekStartDay+dayOfWeek)%7;
    QDate startDate = currentDate.addDays(-(daysBeforeStartDay));
    clearData();
    emit beginResetModel();
    itemsList << new DateItem(0,utilities.getShortDate(startDate),startDate);
    itemsList << new DateItem(1,utilities.getShortDate(startDate.addDays(1)),startDate.addDays(1));
    itemsList << new DateItem(2,utilities.getShortDate(startDate.addDays(2)),startDate.addDays(2));
    itemsList << new DateItem(3,utilities.getShortDate(startDate.addDays(3)),startDate.addDays(3));
    itemsList << new DateItem(4,utilities.getShortDate(startDate.addDays(4)),startDate.addDays(4));
    itemsList << new DateItem(5,utilities.getShortDate(startDate.addDays(5)),startDate.addDays(5));
    itemsList << new DateItem(6,utilities.getShortDate(startDate.addDays(6)),startDate.addDays(6));
    emit endResetModel();

}

void CalendarWeekModel::loadGivenWeekValuesFromOffset(QDate currDateInFocus,int offSetFromCurrentWeek)
{
    UtilMethods utilities;
    QDate startDate;
    QDate currentDate = currDateInFocus;
    int currDayOfWeek = currentDate.dayOfWeek();
    int daysBeforeStartDay = (7-weekStartDay+currDayOfWeek)%7;
    startDate = currentDate.addDays(-(daysBeforeStartDay));

    startDate = startDate.addDays(offSetFromCurrentWeek*7);
    clearData();
    beginResetModel();
    itemsList << new DateItem(0,utilities.getShortDate(startDate),startDate);
    itemsList << new DateItem(1,utilities.getShortDate(startDate.addDays(1)),startDate.addDays(1));
    itemsList << new DateItem(2,utilities.getShortDate(startDate.addDays(2)),startDate.addDays(2));
    itemsList << new DateItem(3,utilities.getShortDate(startDate.addDays(3)),startDate.addDays(3));
    itemsList << new DateItem(4,utilities.getShortDate(startDate.addDays(4)),startDate.addDays(4));
    itemsList << new DateItem(5,utilities.getShortDate(startDate.addDays(5)),startDate.addDays(5));
    itemsList << new DateItem(6,utilities.getShortDate(startDate.addDays(6)),startDate.addDays(6));
    endResetModel();
}


void CalendarWeekModel::loadGivenWeekValuesFromDate(QDate fromDate)
{
    UtilMethods utilities;
    int dayOfWeek = fromDate.dayOfWeek();
    int daysBeforeStartDay = (7-weekStartDay+dayOfWeek)%7;
    QDate startDate = fromDate.addDays(-(daysBeforeStartDay));
    clearData();
    beginResetModel();
    itemsList << new DateItem(0,utilities.getShortDate(startDate),startDate);
    itemsList << new DateItem(1,utilities.getShortDate(startDate.addDays(1)),startDate.addDays(1));
    itemsList << new DateItem(2,utilities.getShortDate(startDate.addDays(2)),startDate.addDays(2));
    itemsList << new DateItem(3,utilities.getShortDate(startDate.addDays(3)),startDate.addDays(3));
    itemsList << new DateItem(4,utilities.getShortDate(startDate.addDays(4)),startDate.addDays(4));
    itemsList << new DateItem(5,utilities.getShortDate(startDate.addDays(5)),startDate.addDays(5));
    itemsList << new DateItem(6,utilities.getShortDate(startDate.addDays(6)),startDate.addDays(6));
    endResetModel();
}


QVariant CalendarWeekModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() > itemsList.count())
        return QVariant();

    DateItem *item = itemsList[index.row()];

    if (role == DateItem::Index)
        return item->index;

    if (role == DateItem::DateValString)
        return item->dateValString;

    if (role == DateItem::CoreDateVal)
        return item->coreDateVal;

    return QVariant();
}

QVariant CalendarWeekModel::data(int index) const
{
    if(index >= itemsList.size())
        index = itemsList.size() - 1;

    return QVariant::fromValue(static_cast<void *>(itemsList[index]));
}

int CalendarWeekModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent);

    return itemsList.size();
}

int CalendarWeekModel::columnCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent);

    return 1;
}

void CalendarWeekModel::clearData()
{

    if(!itemsList.isEmpty())
    {
      while (!itemsList.isEmpty()) {
        delete itemsList.takeFirst();
      }
    }
}

QML_DECLARE_TYPE(CalendarWeekModel);

// =============================================================================
// UT Demo Manager v3.4
// Originally written by UsAaR33
// Project continued by AnthraX after v3.0
// =============================================================================
// udemo.UDComboList: Makes use of new list item.
// =============================================================================
class UDComboList expands UWindowComboList;

// =============================================================================
// Created ~
// =============================================================================
function Created()
{
    ListClass = class'UDComboListItem';
    bAlwaysOnTop = True;
    bTransient = True;
    ItemHeight = 15;
    VBorder = 3;
    HBorder = 3;
    TextBorder = 9;
    Super(UWindowListControl).Created();
}

// =============================================================================
// AddItem ~
// =============================================================================
function AddItem2(string Value, string Value2, int SortWeight, string DateTime)
{
    local UDComboListItem I;

    I = UDComboListItem(Items.Append(class'UDComboListItem'));
    I.Value = Value;
    I.Value2 = Value2;
    I.SortWeight = SortWeight;
    I.DateTime = DateTime;
}

// =============================================================================
// InsertItem ~
// =============================================================================
function InsertItem(string Value, optional string Value2, optional int SortWeight)
{
    local UDComboListItem I;

    I = UDComboListItem(Items.Insert(class'UDComboListItem'));
    I.Value = Value;
    I.Value2 = Value2;
    I.SortWeight = SortWeight;
}

// =============================================================================
// AddSortedItem ~
// =============================================================================
function AddSortedItem(string Value, optional string Value2, optional int SortWeight)
{
    local UDComboListItem I;

    I = UDComboListItem(Items.CreateItem(class'UDComboListItem'));
    I.Value = Value;
    I.Value2 = Value2;
    I.SortWeight = SortWeight;
    Items.MoveItemSorted(I);
}

// =============================================================================
// FindItem ~
// =============================================================================
function UDComboListItem FindItem(string Value)
{
    local UDComboListItem I;

    I = UDComboListItem(Items.Next);

    while(I != None)
    {
        if(I.Value == Value)
            return I;
        I = UDComboListItem(I.Next);
    }
}

defaultproperties
{
}

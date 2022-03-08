// =============================================================================
// UT Demo Manager v3.4
// Originally written by UsAaR33
// Project continued by AnthraX after v3.0
// =============================================================================
// udemo.DemoGrid: Grid window that lists the packages a demo requires.
// =============================================================================
class DemoGrid expands UWindowGrid;

// =============================================================================
// Variables
// =============================================================================
var UWindowGridColumn InstalledColumn;
var int               InstallWidth;
var localized string  InstallType[3];
var localized string  LocPackageName;
var localized string  LocFileSize;
var localized string  LocInstalled;

// =============================================================================
// Created ~
// =============================================================================
function Created()
{
    Super.Created();

    RowHeight = 12;

    AddColumn(LocPackageName, 150);
    AddColumn(LocFileSize, 50);

    InstalledColumn=AddColumn(LocInstalled, winwidth-214);
    InstallWidth=winwidth-214;

    //setup install string
    InstallType[0]=string(false);
    InstallType[1]="Cached";
    InstallType[2]=string(true);
}

// =============================================================================
// PaintColumn ~
// =============================================================================
function PaintColumn(Canvas C, UWindowGridColumn Column, float MouseX, float MouseY)
{
    local DemoList PkgList, l;
    local int Visible;
    local int Count;
    local int Skipped;
    local int Y;
    local int TopMargin;
    local int BottomMargin;

    if(bShowHorizSB)
        BottomMargin = LookAndFeel.Size_ScrollbarWidth;
    else
        BottomMargin = 0;

    TopMargin = LookAndFeel.ColumnHeadingHeight;

    PkgList = DemoMainClientWindow(GetParent(class'DemoMainClientWindow')).Packages;

    Count = PkgList.CountShown();
    if( class'DemoSettings'.default.DisplayMode!=2 ) //option controlled by PBI.
    {
        if( InstalledColumn.WinWidth <= 1 )
        {
            InstalledColumn.ShowWindow();
            InstalledColumn.WinWidth = InstallWidth;
        }
    }
    else
    {
        if( InstalledColumn.WinWidth > 1 )
        {
            InstallWidth = InstalledColumn.WinWidth;
            InstalledColumn.WinWidth = 0;
            InstalledColumn.HideWindow();
        }
    }

    C.drawcolor.r=0;
    C.drawcolor.b=0;
    C.drawcolor.g=0;

    C.Font = Root.Fonts[F_Normal];
    Visible = int((WinHeight - (TopMargin + BottomMargin))/RowHeight);

    VertSB.SetRange(0, Count/*+1*/, Visible);
    TopRow = VertSB.Pos;

    Skipped = 0;

    Y = 1;
    l = DemoList(PKGlist.Next);
    while((Y < RowHeight + WinHeight - RowHeight - (TopMargin + BottomMargin))
        && (l != None))
    {
        if (l.ShowThisItem())
        {
            if(Skipped >= VertSB.Pos)
            {
                switch(Column.ColumnNum)
                {
                    case 0:
                        Column.ClipText( C, 2, Y + TopMargin, l.PackageName );
                        break;

                    case 1:
                        Column.ClipText( C, 2, Y + TopMargin, l.PackageSize );
                        break;

                    case 2:
                        if (l.binstalled==0)
                            C.drawcolor.r=154;
                        Column.ClipText( C, 2, Y + TopMargin, InstallType[l.binstalled]);
                        C.drawcolor.r=0;
                        break;
                }

                Y = Y + RowHeight;
            }

            Skipped ++;
        }

        l = DemoList(l.Next);
    }
}

// =============================================================================
// SortColumn ~
// =============================================================================
function SortColumn(UWindowGridColumn Column)
{
    DemoMainClientWindow(GetParent(class'DemoMainClientWindow')).Packages.SortByColumn(Column.ColumnNum);
}

// =============================================================================
// SelectRow ~
// =============================================================================
function SelectRow(int Row)
{
    //add downloading pop-up here?
}

// =============================================================================
// defaultproperties
// =============================================================================
defaultproperties
{
	LocPackageName="Package Name"
	LocFileSize="File Size"
	LocInstalled="Installed?"
}

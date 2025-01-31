module Components.Atoms.Icons exposing (column, columns, comment, notes, sources, table)

import Components.Atoms.Icon as Icon exposing (Icon)


table : Icon
table =
    Icon.Table


column : Icon
column =
    Icon.Tag


comment : Icon
comment =
    Icon.Chat


notes : Icon
notes =
    Icon.DocumentText


columns : { primaryKey : Icon, foreignKey : Icon, unique : Icon, index : Icon, check : Icon }
columns =
    { primaryKey = Icon.Key
    , foreignKey = Icon.ExternalLink
    , unique = Icon.FingerPrint
    , index = Icon.SortDescending
    , check = Icon.Check
    }


sources : { database : Icon, sql : Icon, json : Icon, aml : Icon, empty : Icon, project : Icon, sample : Icon, remote : Icon }
sources =
    { database = Icon.Database
    , sql = Icon.DocumentText
    , json = Icon.Code
    , aml = Icon.User
    , empty = Icon.Document
    , project = Icon.FolderDownload
    , sample = Icon.Gift
    , remote = Icon.CloudDownload
    }

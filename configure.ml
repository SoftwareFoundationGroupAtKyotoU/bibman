(* days for lending. *)
lending_days = 30

(* number of history records to be output. *)
number_of_history_records = 3

kind = {
  (* options. *)
  values = ["消耗品"; "図書"; "その他"]
}

status = {
  (* options. *)
  values = ["未購入"; "注文済"; "購入済"]
  (* the value meaning "purchase" state. *)
  purchase = "購入済"
}

location = {
  (* options. *)
  values = ["学生部屋"; "教員部屋"; "五十嵐部屋"]
}

mail = {
  (* mail domain. *)
  domain = "fos.kuis.kyoto-u.ac.jp"
  (* name (in the first component) and address (in the second component) of
     mail sender. *)
  sender = ("admin", "admin@fos.kuis.kyoto-u.ac.jp")
  lending = {
    (* subject of the mail for lending notifications. *)
    subject = ""
    (* content of the mail for lending notifications. Each alphabet following
       $ is replaced with information of a book.
       	$t: title
       	$a: author names
       	$p: publisher
       	$y: publisher year
       	$l: location
        *)
    content = ""
  }
}

database = {
  (* host name on which the database service is working *)
  host = "localhost"
  (* user name as who the program connects to the database *)
  username = "postgres"
  (* password for aurhoization of login to the database *)
  password = "postgres"
  (* name of the database to be connected *)
  name = "bibman"
}

script = {
  (* directory where scripts are put *)
  dir = "/home/webserver/public_html/script/"

  file = {
    search = "search_book"
    my_book = "my"
    ediit = "edit"
    add = "add"
  }
}

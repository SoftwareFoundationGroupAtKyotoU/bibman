(* root path of uri. *)
root_path = "/~webserver/"

(* days for lending. *)
lending_days = 30

(* number of history records to be output. *)
number_of_history_records = 3

session = {
  (* period for preserving session. *)
  period = {
    seconds = 0
    minutes = 0
    hours = 0
    days = 1
  }

  (* salt to generate session id. *)
  salt = "f8fjivmrgvh9qb[k]ffefk~jf]fejfffj`@[@aaffcf24fjv"
}

kind = {
  (* options. *)
  values = ["消耗品"; "図書"; "その他"]
  (* the value meaning "expendable" state. *)
  expendable = "消耗品"
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
  sender = ("admin", "admin@...")

  (* name and address of staff. *)
  staff = ("staff", "staff@...")

  lending = {
    (* subject of the mail for lending notifications. *)
    subject = ""
    (* content of the mail for lending notifications. Each alphabet following
       $ is replaced with information of a book.
        $t: title
        $a: author names
        $p: publisher
        $y: publish year
        $l: location
        *)
    content = ""
  }

  (* same as lending except that this settings are for purchase  . *)
  purchase = {
    subject = ""
    content = ""
  }

  (* same as lending except that this settings are for wish-book registration of books. *)
  wish_book_registered = {
    subject = ""
    content = ""
  }

  (* same as lending except that this settings are for removal of a book in wish-book. *)
  wish_book_removed = {
    subject = ""
    content = ""
  }

  (* this settings are for regenerating password, and the following are available.
     $u: user account
     $p: new password
  *)
  regen_password = {
    subject = ""
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
  search = "search_book"
  my_book = "my"
  edit = "edit"
  add = "add"
  remove = "remove"
  catalog = "catalog"
  lending = "lending"
  user = "user"
  tex = "tex"
}

tex = {
  tosho = "tosho.tex"
}

'use strict';

function Class(members) {

  function pickup_mem(key, default_mem) {
    var mem = default_mem;
    if (members.hasOwnProperty(key)) {
      mem = members[key];
      delete members[key];
    }
    return mem;
  }

  var fields = {};
  var constructor = pickup_mem('_constructor', function() {});

  var clss = function() {
    _.extend(this, fields);
    constructor.apply(this, Array.prototype.slice.call(arguments));
  };

  clss.prototype = {};

  for (var key in members) {
    var mem = members[key];
    var hash = typeof mem === 'function' ? clss.prototype : fields;
    hash[key] = mem;
  }

  return clss;
}

function assert(b) {
  console.log(b);
  if (!b) throw {};
}

var Test = Class({
  _constructor: function(x, y, z) {
    this.x = x;
    this.y = y;
    this.z = z;
  },
  methodx: function() { return this.x; },
  methody: function() { return this.y; },
  methodz: function() { return this.z; }
});

var t = new Test(1,2,3);
assert(t.methodx() === 1);
assert(t.methody() === 2);
assert(t.methodz() === 3);

// var SubTest = Class({
//   _constructor: function(x, y, z) {
//     this._super(x,y,z);
//   },
//   methoz: function() { return 100; }
// });

// var s = new SubTest(1,2,3);
// assert(s.methodx() === 1);
// assert(s.methody() === 2);
// assert(s.methodz() === 100);



// var BookList = Class({
//   constructor: function(user, books, lendings, histories) {
//     this._user = user;
//     this._books = books;
//     this._lendings = lendings;
//     this._histories = histories;
//   },
//   method1:   
// });

// Handlebars.registerHelper('join', function(array, sep, options) {
//   return array.map(function(item) {
//     return options.fn(item);
//   }).join(sep);
// });

var BookList = Class({
  _constructor: function(user, books, lendings, histories) {
    this._user = user;
    this._books = books;
    this._lendings = lendings;
    this._histories = histories;
  }
});

(function () {

  if (!console || !console.log) {
    console = console || {};
    console.log = function () {}
  };

  function log(action, msg) {
    console.log(action + ': ' + msg);
  }

  var API = {};
  function register_api(info) {
    // name, url, type, opt_settings) {

    var default_settings = _.extend(
      {
        dataType: 'json',
        type: info.type,
        url: './../api/' + info.url
      },
      info.settings || {}
    );

    var error = function (xhr, status, err) {
      log('API', 'FAIL TO INVOKE '+ info.name +' IN '+ info.url +' ( '+ err +')');
    };

    API[info.name] = function (data, opt_settings) {
      opt_settings = opt_settings || {};

      var settings = _.clone(default_settings);
      settings.data = data;

      settings = _.extend(settings, opt_settings);

      settings.error = function() {
        error.apply(this, arguments);
        if (settings.error) settings.error.apply(this, arguments);
      };

      return $.ajax(settings);
    };
  }

  [
    { name: 'config', url: 'config.cgi', type: 'GET' },
    { name: 'search_book', url: 'search.cgi', type: 'GET' },
    { name: 'lending', url: 'lending.cgi', type: 'GET' },
    { name: 'history', url: 'history.cgi', type: 'GET' },
    { name: 'edit', url: 'edit.cgi', type: 'POST',
      settings: { dataType: 'text' }
    }
  ].forEach(register_api);

  function setup(config_res) {
    var config = config_res[0];

    var book_item_template = Handlebars.compile($('#book-item-template').html());
    /* result is ordered by books */
    function instantiate_book_dom (data) {
      var books = data.books;
      var lendings = data.lendings;
      var histories = data.histories;

      if (books.length === 0) return;

      var lending_hash = {};
      lendings.forEach(function (lending) {
        lending_hash[lending.id] = lending;
      });

      var history_hash = {};
      histories.forEach(function (history) {
        history_hash[history.id] = history.history;
      });

      var items = books.map(function (book) {
        var id = book.id;
        return {
          book: book,
          lending: lending_hash[id],
          history: history_hash[id]
        };
      });

      return book_item_template({ items: items });
    }

    // books_json.map(function (book) {
    //       book.author = book.author.join(', ');
    //       return books;
    //     });
    //   );

    // var $template = $('#book-item-template').clone();

    // var prefix = 'bt-';
    // var $book = $template.clone();

    // [
    //   'title',
    //   'publish_year',
    //   'rental_deadline',
    //   'publisher',
    //   'isbn',
    //   'kind'
    // ].forEach(function (key) {
    //   $template.find(prefix+key).text(data[key]);
    // });

    // var repfun_hash = {
    //   author: function (authors, $template) { $template.text(authors.join(', ')); },
    //   rental_status: function (status, $template) {
    //     status.forEach(function (key) { $template.find(key).css('display', ''); });
    //   },
    //   history: function (history, $template) {
    //     history.forEach(function (record) {
    //       $account = $(
    //     });
    //   },
    //   tex: 1
    // };

    // for (var key in repfun_hash) {
    //   repfun_hash[key](data[key], $template);
    // }
    // }

    /* search */
    (function () {
      var user = { account: 't-sekiym' }; /* TODO */
      var class_display_none = 'display-none';

      function search_book(data, callback) {
        API.search_book(data)
          .done(
            function(books) {
              var ids = books.map(function(book) { return book.id; });
              $.when(
                API.history({ id: ids }),
                API.lending({ id: ids })
              ).done(
                function(res_histroy, res_lending) {
                  callback({
                    books: books,
                    lendings: res_lending[0],
                    histories: res_histroy[0],
                    count: books.length
                  });
                }
              );
            });
      }

      function process_search_result(user, result) {
        /* book */
        result.books.forEach(function (book) {
          book.author = book.author.join(', ');
        });

        /* lendings */
        result.lendings.forEach(function (lending) {
          if (lending.owner === user.account) {
            lending.owner_me = true;
          }
          else if (lending.owner) {
            lending.owner_other = true;
          }

          lending.reserver_count = lending.reserver.length;
        });
      }

      var edit_text_template = Handlebars.compile(
'<form style="display: inline">\
  <input type="text" class="edit-value" value="{{ value }}" />\
  <input type="submit" class="edit-complete" value="OK" />\
  <input type="submit" class="edit-cancel" value="キャンセル" />\
</form>'
      );
      function form_edit_text(value) {
        return $(edit_text_template({ value: value }));
      }

      var edit_select_template = Handlebars.compile(
'<form style="display: inline">\
  <select class="edit-value" value="{{ value }}">\
  {{#each options}}\
    <option value="{{ this }}">{{ this }}</option>\
  {{/each}}\
  <input type="submit" class="edit-complete" value="OK" />\
  <input type="submit" class="edit-cancel" value="キャンセル" />\
</form>'
      );
      function form_edit_select(value, options) {
        var $form = $(edit_select_template({ value: value, options: options }));
        $form.find('option').each(function () {
          if ($(this).val() === value) this.selected = true;
        });
        return $form;
      }

      function set_trigger_to_edit_form($form) {
        var $dfd = $.Deferred();

        $form.find('.edit-complete').click(function() {
          $dfd.resolve($form.find('.edit-value').val());
          return false;
        });

        $form.find('.edit-cancel').click(function() {
          $dfd.reject();
          return false;
        });

        return $dfd.promise();
      }

      function edit_text($edit_mark, form_generator) {
        if (!$edit_mark.hasClass('edit-mark')) return;

        var DOM_block = $edit_mark.get(0).parentNode;
        var $block = $(DOM_block);

        /* text */
        var $content = $block.children('.item-content');
        var DOM_content = $content.get(0);
        var $edit_form = form_generator($content.text());
        var DOM_edit_form = $edit_form.get(0);

        DOM_block.replaceChild(DOM_edit_form, DOM_content);
        $edit_mark.css('display', 'none');

        var $dfd = $.Deferred();

        set_trigger_to_edit_form($edit_form)
          .done(function (val) {
            if (val) $content.text(val);
            $dfd.resolve(val);
          })
          .fail(function () {
            $dfd.reject();
          })
          .always(function () {
            DOM_block.replaceChild(DOM_content, DOM_edit_form);
            $edit_mark.css('display', '');
          });

        return $dfd.promise();
      }

      function set_trigger($list) {
        $list.children().each(function (idx) {
          var $item = $(this);

          /* expansion */
          var $toggled = $item.find('.edit-mark,.book-description');

          $item.find('.expand').click(function() {
            $(this).children().each(function () {
              $(this).toggleClass(class_display_none);
            });
            $toggled.toggleClass(class_display_none);
          });

          /* edit */
          $item.click(function(e) {
            var $target = $(e.target);
            if (!$target.hasClass('edit-mark')) return;

            var $dfd;

            switch ($target.data('type')) {
              case 'text':
              $dfd = edit_text($target, form_edit_text);
              break;
              case 'select':
              $dfd = edit_text(
                $target,
                function(val) {
                  return form_edit_select(val, config.book[$target.data('item')].item);
                }
              );
              break;
            }

            $dfd.done(function(val) {
              API.edit({
                target: 'book',
                item: $target.data('item'),
                value: val
              })
              .fail(function() {
                window.alert('入力に誤りがあります．');
              });
            });
          });
        });
      }

      function form_book_list(books_info) {
        process_search_result(user, books_info);
        var $list = $('<div />').html(instantiate_book_dom(books_info)).find('.book-list');
        set_trigger($list);
        return $list;
      }

      function sort_book_list(books_info, item, des) {
        var i = des ? -1 : 1;
        books_info.books.sort(
          function(x, y) { return i * x[item].localeCompare(y); }
        );
        return books_info;
      }

      function form_list_step(count, limit, curr_page_no) {
        return _.range(books_info.count / limit + 1).map(function (i) {
          var no = i + 1;
          var $a = $('<a>' + no + '</a>');
          if (no !== page_no) {
            $a.attr('href', '""');
            /* TODO: trigger */
          }
          return $a;
        });
      }

      var $search_text = $('#search-text');

      $('#search-form').submit(function (e) {
        e.preventDefault();

        var keyword = $search_text.val();
        if (keyword === '') return;

        var sort = $('#search-sort').val();
        var limit = $('#search-number-limit').val();

        search_book(
          { keyword: keyword },
          function(result) {
            if (result.books.length === 0) {
              window.alert('キーワードにヒットする本は見つかりませんでした．');
            }
            else {
              var $list = form_book_list(result);
              $('#book-search-list').empty().append($list);
            }
          }
        );
      });
    })();
  }

  var $dfd = $.Deferred();
  $(document).ready($dfd.resolve);
  $.when(API.config(undefined), $dfd).done(setup);

})();

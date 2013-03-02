'use strict';

var Bibman = {};

Bibman.log = (function () {
  var log = console && console.log ? console.log : function () {};
  return function(action, msg) {
    log(action + ': ' + msg);
  };
})();

Bibman.Class = function(members) {

  function draw_member(key, default_mem) {
    var mem = default_mem;
    if (members.hasOwnProperty(key)) {
      mem = members[key];
      delete members[key];
    }
    return mem;
  }

  var fields = {};
  var constructor = draw_member('_constructor', function() {});

  var clss = function() {
    _.extend(this, fields);
    constructor.apply(this, arguments);
  };

  clss.prototype = {};

  for (var key in members) {
    var mem = members[key];
    var hash = (typeof mem === 'function') ? clss.prototype : fields;
    hash[key] = mem;
  }

  return clss;
};

function assert(b) {
  console.log(b);
  if (!b) throw {};
}

var Test = Bibman.Class({
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

Bibman.API = {};
(function() {

  function register_api(api) {
    var default_settings = _.extend(
      {
        dataType: 'json',
        type: api.type,
        url: './../api/' + api.url
      },
      api.settings || {}
    );

    var log_error = function (xhr, status, err) {
      Bibman.log('API', 'FAIL TO INVOKE '+ api.name +' IN '+ api.url +' ( '+ err +')');
    };

    Bibman.API[api.name] = function (data, opt_settings) {
      opt_settings = opt_settings || {};

      var settings = _.clone(default_settings);
      settings.data = data;
      _.extend(settings, opt_settings);

      var error = settings.error;
      settings.error = function() {
        log_error.apply(this, arguments);
        if (error) error.apply(this, arguments);
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
})();

Bibman.BookList = Bibman.Class({
  _constructor: function(user, books_info) {

    this.books = books_info.books;
    this.lendings = books_info.lendings;
    this.histories = books_info.histories;

    /* book */
    this.books.forEach(function (book) {
      book.author = book.author.join(', ');
    });

    /* lendings */
    this.lendings.forEach(function (lending) {
      if (lending.owner === user.account) {
        lending.owner_me = true;
      }
      else if (lending.owner) {
        lending.owner_other = true;
      }

      lending.reserver_count = lending.reserver.length;
    });
  },

  count: function() {
    return this.books.length;
  },

  sort: function(item, des) {
    if (this.count() === 0) return;

    var i = des ? -1 : 1;
    var compare = (typeof this.books[0][item] === 'number') ?
      function(x, y) { return x - y; } :
      function(x, y) { return x.localeCompare(y); };

    this.books.sort(
      function(x, y) { return i * compare(x[item], y[item]);}
    );
  }
});

var class_display_none = 'display-none';

var edit_text = (function() {

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

  function set_trigger($form) {
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

  /* TODO: strong dependency on structure of html... */
  function edit_text($edit_mark, form_generator) {
    var DOM_block = $edit_mark.get(0).parentNode;
    var $block = $(DOM_block);

    var $content = $block.children('.item-content');
    var DOM_content = $content.get(0);
    var content_val = $content.text();

    var $edit_form = form_generator(content_val);
    var DOM_edit_form = $edit_form.get(0);

    DOM_block.replaceChild(DOM_edit_form, DOM_content);
    $edit_mark.css('display', 'none');

    var $dfd = $.Deferred();

    set_trigger($edit_form)
      .done(function (val) {
        if (val) $content.text(val);

        $dfd.resolve(val, function() {
          $content.text(content_val);
        });
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

  return function($edit_mark, setting) {
    switch (setting.type) {
    case 'text':
      return edit_text($edit_mark, form_edit_text);
    case 'select':
      return edit_text(
        $edit_mark,
        function(val) {
          return form_edit_select(val, setting.values);
        }
      );
    }
  };
})();

Bibman.config = {};

Bibman.UI = {};

Bibman.UI.BookList = Bibman.Class({
  _constructor: function(booklist, booklist_template) {
    this._booklist = booklist;
    if (this._booklist.count() === 0) return null;

    this._booklist_template = booklist_template;
    this._edit_fail_callbacks = $.Callbacks();

    var self = this;

    this._lending_hash = {};
    this._booklist.lendings.forEach(function (lending) {
      self._lending_hash[lending.id] = lending;
    });

    this._history_hash = {};
    this._booklist.histories.forEach(function (history) {
      self._history_hash[history.id] = history.history;
    });
  },

  /* ordered by books */
  _htmlify_book_list: function (books) {
    var self = this;
    var items = books.map(function (book) {
      var id = book.id;
      return {
        book: book,
        lending: self._lending_hash[id],
        history: self._history_hash[id]
      };
    });

    return this._booklist_template({ items: items });
  },

  _set_event_handler: function($list) {
    var self = this;

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

        edit_text($target, {
          type: $target.data('type'),
          values: (Bibman.config.book[$target.data('item')] || {}).values
        }).done(function(val, prevent) {
          Bibman.API.edit({
            target: 'book',
            item: $target.data('item'),
            value: val
          }).fail(function() {
            prevent();
            self._edit_fail_callbacks.fire();
          });
        });
      });
    });
  },

  form: function(offset, limit) {
    var books = this._booklist.books.slice(offset, offset + limit);
    var $list = $('<div />').html(this._htmlify_book_list(books)).find('.book-list');
    this._set_event_handler($list);
    return $list;
  },

  on_fail_edit: function(callback) {
    this._edit_fail_callbacks.add(callback);
  }
});

Bibman.UI.ListStep = Bibman.Class({
  _constructor: function(count, limit) {
    this._callbacks = $.Callbacks();

    var self = this;
    this._links = _.range(parseInt(count / limit, 10) + 1).map(
      function (i) {
        var $a = $('<a>'+ (i + 1) +'</a>');
        self._set_event_handler($a, i);
        return $a;
      });

    this._$prefix = $('<a>&lt;</a>');
    this._$suffix = $('<a>&gt;</a>');
  },

  _set_event_handler: function($a, page_idx) {
    var self = this;
    $a.click(function(e) {
      e.preventDefault();
      if ($a.attr('href')) {
        self._callbacks.fire(page_idx);
      }
      return false;
    });
  },

  _set_attribute: function($a, page_idx, curr_page_idx) {
    if (page_idx === curr_page_idx) {
        $a.removeAttr('href');
      }
      else {
        $a.attr('href', '#');
      }
  },

  _last_index: function() {
    return this._links.length - 1;
  },

  form: function(page_idx) {
    var self = this;
    this._links.forEach(function ($a, idx) {
      self._set_attribute($a, idx, page_idx);
    });

    var $prefix = this._$prefix.clone();
    var prefix_idx = (page_idx === 0) ? 0 : page_idx - 1;
    this._set_event_handler($prefix, prefix_idx);
    this._set_attribute($prefix, prefix_idx, page_idx);

    var $suffix = this._$suffix.clone();
    var suffix_idx = (page_idx === this._last_index()) ?
      this._last_index() : page_idx + 1;
    this._set_event_handler($suffix, suffix_idx);
    this._set_attribute($suffix, suffix_idx, page_idx);

    var $block = $('<span />');
    $block.append($prefix, this._links.concat([$suffix]));

    return $block;
  },

  on_change_page: function(callback) {
    this._callbacks.add(callback);
  }
});

Bibman.user = undefined;

/* FIXME(TODO): this class is awful... I should separate controller from view */
Bibman.BookSearchDrawer = Bibman.Class({
  _constructor: function(user, result) {
    this._booklist = new Bibman.BookList(user, result);

    this._booklistUI = new Bibman.UI.BookList(
      this._booklist,
      Handlebars.compile($('#book-item-template').html())
    );
    this._booklistUI.on_fail_edit(function() {
      window.alert('入力に誤りがあります．');
    });

    this._page_idx = 0;
    this._limit = this._current_limit();
    this._new_stepUI();

    $('#search-sort').change(_.bind(this._change_order_event, this));
    $('#search-number-limit').change(_.bind(this._change_limit_event, this));
  },

  _new_stepUI: function() {
    this._stepUI = new Bibman.UI.ListStep(
      this._booklist.count(),
      this._limit
    );
    this._stepUI.on_change_page(_.bind(this._change_page_index_event, this));
  },

  _current_limit: function() {
    return Number($('#search-number-limit').val());
  },

  _change_order_event: function() {
    this.book_sort();
    this._page_idx = 0;
    this.draw_list();
  },

  _change_limit_event: function() {
    this._limit = this._current_limit();
    this._page_idx = 0;

    this._new_stepUI();

    this.draw_list();
  },

  _change_page_index_event: function(idx) {
    this._page_idx = idx;
    this.draw_list();
  },

  book_sort: function() {
    var str = $('#search-sort').val();
    var regexp = /^([^-]+)-(.+)$/;
    var match = regexp.exec(str);
    var des = (match[1] === 'des');
    var item =  match[2];

    this._booklist.sort(item, des);
  },

  draw_list: function() {
    var $list = this._booklistUI.form(this._page_idx * this._limit, this._limit);
    $('#book-search-list').empty().append($list);

    var $step = this._stepUI.form(this._page_idx);
    $('#search-contents .list-step').each(function () {
      $(this).empty().append($step.clone(true));
    });
  }
});

Bibman.init = (function() {
  var init = function(account) {
    Bibman.user = { account: account };

    var $dfd = $.Deferred();
    $(document).ready($dfd.resolve);
    $.when(Bibman.API.config(undefined), $dfd).done(
      function(config_res) {
        Bibman.config = config_res[0];
        init.load_callbacks.fire();
      }
    );
  };

  init.load_callbacks = $.Callbacks();

  return init;
})();

/* swtich contents */
Bibman.switch_tab = function(id) {
  $('.contents').css('display', 'none');
  $('#' + id).css('display', '');
};

/* search */
Bibman.init.load_callbacks.add(function () {
  function search_book(data, callback) {
    Bibman.API.search_book(data)
      .done(function(books) {
        var ids = books.map(function(book) { return book.id; });
        $.when(
          Bibman.API.history({ id: ids }),
          Bibman.API.lending({ id: ids })
        ).done(
          function(res_histroy, res_lending) {
            callback({
              books: books,
              lendings: res_lending[0],
              histories: res_histroy[0]
            });
          }
        );
      });
  }

  /* search */
  $('#search-form').submit(function (e) {
    e.preventDefault();

    var keyword = $('#search-text').val();
    if (keyword === '') return;

    search_book({ keyword: keyword }, function(result) {
      if (result.books.length === 0) {
        window.alert('キーワードにヒットする本は見つかりませんでした．');
        return;
      }

      var drawer = new Bibman.BookSearchDrawer(Bibman.user, result);
      drawer.book_sort();
      drawer.draw_list();
    });
  });
});

/* book register */
Bibman.init.load_callbacks.add(function() {
  /* set options in select form */
  function add_options($select, values) {
      values.forEach(function (val) {
        var $option = $('<option />');
        $option.val(val);
        $option.text(val);
        $select.append($option);
      });
  }

  add_options(
    $('#book-register-publisher'),
    Bibman.config.book.publisher.values
  );
  add_options(
    $('#book-register-kind'),
    Bibman.config.book.kind.values
  );

  /* wishlist */


  /* book register */
  
});

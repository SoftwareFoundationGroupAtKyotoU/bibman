'use strict';

var Bibman = {};

Bibman.Handlebars = {};
Bibman.Handlebars.cache = {};

Handlebars.registerHelper('template', function(name, context) {
  var sub_template = Bibman.Handlebars.cache[name];
  if (!sub_template) {
    sub_template =
      Bibman.Handlebars.cache[name] =
      Handlebars.compile($('#' + name).html());
  }

  var ctx = $.extend({}, context.hash, context.hash.context || {});
  return new Handlebars.SafeString(sub_template(ctx));
});


Bibman.log = (function () {
  var log = console && console.log ? console.log : function () {};
  return function(action, msg) {
    log(action + ': ' + msg);
  };
})();

Bibman.Class = (function () {

  function set_method(clss, base, name, method) {
    var super_call = function () {
      var s = this._super;
      var ret = base.prototype[name].apply(this, arguments);
      this._super = s;
      return ret;
    };

    clss.prototype[name] = function () {
      this._super = super_call;
      return method.apply(this, arguments);
    };
  }

  return function(members) {
    var base = members._base || {};
    var constructor = members._constructor;
    if (!constructor && members._base) {
      constructor = function () {
        base.prototype._constructor.apply(this, arguments);
      };
    }
    constructor = constructor || function () {};

    members._constructor = constructor;

    var fields = {};
    var clss = function() {
      _.extend(this, fields);
      return this._constructor.apply(this, arguments);
    };

    clss.prototype = _.clone(base.prototype || {});

    for (var name in members) {
      var mem = members[name];
      if (typeof mem === 'function') {
        set_method(clss, base, name, mem);
      }
      else {
        clss.prototype[name] = mem;
      }
    }

    return clss;
  };
})();

Bibman.config = {};

Bibman.API = {};
Bibman.API.ROOT = './../api/';

(function() {

  function register_api(api) {
    var default_settings = _.extend(
      {
        dataType: 'json',
        type: api.type,
        url: Bibman.API.ROOT + api.url,
        traditional: true,
        data: {}
      },
      api.settings || {}
    );

    var log_error = function (xhr, status, err) {
      Bibman.log('API', 'FAIL TO INVOKE '+ api.name +' IN '+ api.url +' ( '+ err +')');
    };

    Bibman.API[api.name] = function (data, opt_settings) {
      opt_settings = opt_settings || {};

      var settings = _.clone(default_settings);
      _.extend(settings.data, data);
      _.extend(settings, opt_settings);

      var error = settings.error;
      settings.error = function() {
        log_error.apply(this, arguments);
        if (error) error.apply(this, arguments);
      };

      return $.ajax(settings).fail(function (jqXHR) {
        if (jqXHR.status === 403 &&
            jqXHR.responseText === "You aren't certificated") {
          window.alert('セッションの有効期限を過ぎました．再度ログインし直してください');
        }
      });
    };
  }

  [
    { name: 'config', url: 'config.cgi', type: 'GET' },
    { name: 'search_book', url: 'search.cgi', type: 'GET' },
    { name: 'lending', url: 'lending.cgi', type: 'GET' },
    { name: 'history', url: 'history.cgi', type: 'GET' },
    { name: 'edit_book', url: 'edit.cgi', type: 'POST',
      settings: { dataType: 'text' }
    },
    { name: 'wishbook', url: 'wish_book.cgi', type: 'GET',
      settings: { data: { action: 'list' } }
    },
    { name: 'register_book', url: 'register.cgi', type: 'POST' },
    { name: 'lend_book', url: 'lend_book.cgi', type: 'POST',
      settings: { dataType: 'text' }
    },
    { name: 'my_book', url: 'my_book.cgi', type: 'GET' },
    { name: 'add', url: 'add.cgi', type: 'POST',
      settings: { dataType: 'text' }
    },
    { name: 'remove_wishbook', url: 'wish_book.cgi', type: 'POST',
      settings: { data: { action: 'remove' }, dataType: 'text' }
    },
    { name: 'logout', url: 'logout.cgi', type: 'POST',
      settings: { dataType: 'text' }
    },
    { name: 'allocate_label', url: 'allocate_label.cgi', type: 'POST',
      settings: { dataType: 'text' }
    }
  ].forEach(register_api);
})();

/* override lend book API to notify changes of lending states */
(function() {
  var api = Bibman.API.lend_book;

  Bibman.API.lend_book = function (data) {
    return api.apply(this, arguments).done(function() {
      Bibman.API.lending({ id: data.id }).done(function(arr) {
        Bibman.API.lend_book.lending_callbacks.fire(
          data.id, arr[0] || null
        );
      });
    });
  };

  Bibman.API.lend_book.lending_callbacks = $.Callbacks();
})();


/* Classes for book list */
Bibman.BookList = Bibman.Class({
  _constructor: function(user, books_info) {

    this._user = user;
    this.books = books_info.books;
    this._lending_hash = {};
    this._history_hash = {};

    this.books.forEach(function(book) {
      book.author = book.author.join(', ');
    });

    var self = this;

    (books_info.lendings || []).forEach(function (lending) {
      self._trans_lending(lending);
      self._lending_hash[lending.id] = lending;
    });

    (books_info.histories || []).forEach(function (history) {
      self._history_hash[history.id] = history.history;
    });
  },

  _trans_lending: function(lending) {
    if (lending.owner === this._user.account()) {
      lending.owner_me = true;
    }
    else if (lending.owner) {
      lending.owner_other = true;
    }

    var self = this;
    lending.reserver_me = _.some(lending.reserver, function (account)  {
      return self._user.account() === account;
    });

    lending.reserver_count = lending.reserver.length;
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
  },

  _remove: function(list, id) {
    for (var i = 0; i < list.length; ++i) {
      if (list[i].id === id) {
        list.splice(i, 1);
        break;
      }
    }
  },

  remove: function(id) {
    this._remove(this.books, id);
    delete this._lending_hash[id];
    delete this._history_hash[id];
  },

  unshift_book: function(book) {
    this.books.unshift(book);
  },

  update_lending: function(lending, id) {
    if (lending === null) {
      delete this._lending_hash[id];
      return {};
    }
    else {
      this._trans_lending(lending);
      this._lending_hash[lending.id] = lending;
      return lending;
    }
  },

  lending: function(id) {
    return this._lending_hash[id];
  },

  history: function(id) {
    return this._history_hash[id];
  }
});

Bibman.UI = {};

Bibman.UI.hide = function () {
  Array.prototype.slice.apply(arguments).forEach(function(elem) {
    $(elem).css('display', 'none');
  });
};

Bibman.UI.show = function () {
  Array.prototype.slice.apply(arguments).forEach(function(elem) {
    $(elem).css('display', '');
  });
};

Bibman.UI.edit_text = (function() {

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
    Bibman.UI.hide($edit_mark);

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
        Bibman.UI.show($edit_mark);
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

Bibman.BookList.UI = (function () {

  function set_lending_event_handler(booklist, $lending_block) {

    var id = $lending_block.parents('.book-item').data('book-id');
    function set_event_handler(action, $target) {
      $target.submit(function() {
        Bibman.API.lend_book({
          action: action,
          id: id
        });

        return false;
      });
    }

    var $lending = $lending_block.find('.lending-form');
    var $return = $lending_block.find('.return-form');
    var $reserve = $lending_block.find('.reserve-form');
    var $cancel_reservation = $lending_block.find('.cancel-reservation-form');

    [
      [ 'lend', $lending ],
      [ 'return', $return ],
      [ 'reserve', $reserve ],
      [ 'cancel', $cancel_reservation ]
    ].forEach(function(arr) {
      set_event_handler.apply(this, arr);
    });
  }

  return Bibman.Class({
    _constructor: function(booklist, booklist_template, template_option) {
      this._booklist = booklist;

      this._booklist_template = booklist_template;
      this._template_option = template_option || {};
      this._edit_complete_callbacks = $.Callbacks();
      this._edit_fail_callbacks = $.Callbacks();
      this._edit_success_callbacks = $.Callbacks();
    },

    /* ordered by books */
    _htmlify_book_list: function (books) {
      var self = this;
      var items = books.map(function (book) {
        var id = book.id;
        return {
          book: book,
          lending: self._booklist.lending(id),
          history: self._booklist.history(id)
        };
      });

      return this._booklist_template({
        items: items,
        option: this._template_option
      });
    },

    _edit_event_handler: function(e) {
      var self = this;
      var $target = $(e.target);
      var $item = $(e.delegateTarget);

      Bibman.UI.edit_text($target, {
        type: $target.data('type'),
        values: (Bibman.config.book[$target.data('item')] || {}).values
      }).done(function(val, prevent) {
        var p = false;
        self._edit_complete_callbacks.fire({
          target: e.target,
          value: val,
          prevent: function() { p = true; }
        });

        if (p) prevent();
        else {
          Bibman.API.edit_book({
            id: $item.data('book-id'),
            item: $target.data('item'),
            value: val
          }).done(function() {
            self._edit_success_callbacks.fire({
              target: e.target,
              value: val
            });
          }).fail(function() {
            prevent();
            self._edit_fail_callbacks.fire({
              target: e.target,
              value: val
            });
          });
        }
      });
    },

    _set_event_handler: function($list) {
      var self = this;
      var lending_template = Handlebars.compile($('#lending-item-template').html());

      $list.children().each(function (idx) {
        var class_display_none = 'display-none';
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
          if ($target.hasClass('edit-mark')) {
            self._edit_event_handler(e);
          }
        });

        /* lending */
        var book_id = $item.data('book-id');
        var $lending_block = $item.find('.lending');
        Bibman.UI.set_lending_event_handler(self._booklist, $lending_block);
        Bibman.API.lend_book.lending_callbacks.add(function(target_id, lending) {
          if (target_id !== book_id) return;

          lending = self._booklist.update_lending(lending, book_id);
          $lending_block.empty().html(lending_template(lending));
          Bibman.UI.set_lending_event_handler(self._booklist, $lending_block);
        });
      });
    },

    form: function(offset, limit) {
      var books = this._booklist.books.slice(offset, offset + limit);
      var $list = $('<div></div>').html(this._htmlify_book_list(books)).find('.book-list');
      this._set_event_handler($list);
      return $list;
    },

    on_complete_edit: function(callback) {
      this._edit_complete_callbacks.add(callback);
    },

    on_succeed_in_edit: function(callback) {
      this._edit_success_callbacks.add(callback);
    },

    on_fail_edit: function(callback) {
      this._edit_fail_callbacks.add(callback);
    }
  });
})();

/* UI class for next/previous links, i.e., < 1 2 3 ... n > */
Bibman.ListStepUI = Bibman.Class({
  _constructor: function(count, hash) {
    this._count = count;
    this._hash_link = hash;
    this._callbacks = $.Callbacks();
  },

  _set_event_handler: function($a, page_idx) {
    var self = this;
    $a.click(function() {
      if ($a.attr('href')) {
        self._callbacks.fire({ target: $a.get(0), value: page_idx});
        window.location.hash = self._hash_link;
        window.location.hash = '';
      }
    });
  },

  _new_links: function(count_per_page) {
    var self = this;
    return _.range(parseInt((this._count - 1) / count_per_page, 10) + 1).map(
      function (i) {
        var $a = $('<a>'+ (i + 1) +'</a>');
        self._set_event_handler($a, i);
        return $a;
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

  form: function(page_idx, count_per_page) {
    var links = this._new_links(count_per_page);
    var self = this;
    links.forEach(function ($a, idx) {
      self._set_attribute($a, idx, page_idx);
    });

    var $prefix = $('<a>&lt;</a>');
    var prefix_idx = (page_idx === 0) ? 0 : page_idx - 1;
    this._set_event_handler($prefix, prefix_idx);
    this._set_attribute($prefix, prefix_idx, page_idx);

    var $suffix = $('<a>&gt;</a>');
    var last_idx = links.length - 1;
    var suffix_idx = (page_idx === last_idx) ? last_idx : page_idx + 1;
    this._set_event_handler($suffix, suffix_idx);
    this._set_attribute($suffix, suffix_idx, page_idx);

    var $block = $('<span />');
    $block.append($prefix, links.concat([$suffix]));

    return $block;
  },

  on_change_page: function(callback) {
    this._callbacks.add(callback);
  }
});

/* Abstract class */
Bibman.BookList.UI.Drawer = Bibman.Class({
  _constructor: function(booklist, template_option) {
    this._booklistUI = new Bibman.BookList.UI(
      booklist,
      Handlebars.compile($('#book-item-template').html()),
      template_option
    );
    this._booklistUI.on_fail_edit(function() {
      window.alert('入力に誤りがあります．');
    });
  },

  booklistUI: function() {
    return  this._booklistUI;
  },

  draw: undefined
});

Bibman.BookList.UI.SortDrawer = Bibman.Class({
  _base: Bibman.BookList.UI.Drawer,
  _constructor: function(booklist, template_option, elements) {
    this._super(booklist, template_option);

    this._booklist = booklist;
    this._$list = elements.$list;
    this._$sort = elements.$sort;
  },

  draw: function(offset, limit) {
    var $list = this._booklistUI.form(offset, limit);
    this._$list.empty().append($list);
  },

  _sort: function() {
    var str = this._$sort.val();
    var regexp = /^([^-]+)-(.+)$/;
    var match = regexp.exec(str);
    var des = (match[1] === 'des');
    var item =  match[2];
    this._booklist.sort(item, des);
  },

  list: function() {
    this._sort();
    this.draw(0, this._booklist.count());
  }
});

Bibman.BookList.UI.SearchDrawer = Bibman.Class({
  _base: Bibman.BookList.UI.SortDrawer,
  _constructor: function(booklist, stepUI, elements) {
    this._super(booklist, {}, elements);

    this._step_draw = function(page_idx, count_per_page) {
      var $step = stepUI.form(page_idx, count_per_page);
      elements.$step.each(function () {
        $(this).empty().append($step.clone(true));
      });
    };

    this._count_per_page = function () {
      return elements.$count_per_page.val();
    };
  },

  draw: function(page_idx) {
    var count_per_page = this._count_per_page();
    this._super(page_idx * count_per_page, count_per_page);
    this._step_draw(page_idx, count_per_page);
  }
});

Bibman.BookList.UI.AllDrawer = Bibman.Class({
  _base: Bibman.BookList.UI.Drawer,
  _constructor: function(booklist, booklist_template, $list) {
    this._super(booklist, booklist_template);
    this._booklist = booklist;
    this._$list = $list;
  },

  draw: function() {
    var $list = this._booklistUI.form(0, this._booklist.count());
    this._$list.empty().append($list);
  }
});


/* init function */
Bibman.user = undefined;

Bibman.init = (function() {
  var init = function(account) {

    var $dfd = $.Deferred();
    $(document).ready($dfd.resolve);

    $.when(Bibman.API.config(undefined), $dfd).done(
      function(config_res) {
        Bibman.config = config_res[0];

        var account = $('#account').val();
        Bibman.user = { account: function() { return account; } };

        init.load_callbacks.fire();
      }
    );
  };

  init.load_callbacks = $.Callbacks();

  return init;
})();

Bibman.collect_lendings_and_histories = function(books, callback) {
  if (books.length === 0) {
    callback({
      books: books,
      lendings: [],
      histories: []
    });
  }
  else {
    var ids = books.map(function(book) { return book.id; });
    $.when(
      Bibman.API.history({ id: ids }),
      Bibman.API.lending({ id: ids })
    ).done(function(res_histroy, res_lending) {
      callback({
        books: books,
        lendings: res_lending[0],
        histories: res_histroy[0]
      });
    });
  }
};

/* search */
Bibman.init.load_callbacks.add(function () {
  function search_book(data, callback) {
    Bibman.API.search_book(data).done(function(books) {
      Bibman.collect_lendings_and_histories(books, callback);
    });
  }

  function on_search() {
    var query = $('#search-text').val();
    if (query === '') return;

    search_book({ query: query }, function(result) {
      var booklist = new Bibman.BookList(Bibman.user, result);
      if (booklist.count() === 0) {
        window.alert('キーワードにヒットする本は見つかりませんでした．');
        return;
      }

      var stepUI = new Bibman.ListStepUI(booklist.count(), 'top-anchor');
      var $sort = $('#search-sort');
      var $count_per_page = $('#search-count-per-page');

      var drawer = new Bibman.BookList.UI.SearchDrawer(
        booklist,
        stepUI,
        {
          $list: $('#book-search-list'),
          $sort: $sort,
          $step: $('#search-contents .list-step'),
          $count_per_page: $count_per_page
        }
      );

      stepUI.on_change_page(function(e) { drawer.draw(e.value); });

      $sort.unbind('change');
      $sort.change(function() { drawer.list(); });

      $count_per_page.unbind('change');
      $count_per_page.change(function() { drawer.draw(0); });

      drawer.list();
    });
  }

  /* search */
  $('#search-form').submit(function (e) {
    on_search();
    return false;
  });
});

/* book register */
Bibman.init.load_callbacks.add(function() {

  /* initialize form */
  /** set options in select form **/
  function add_options($select, values) {
      values.forEach(function (val) {
        var $option = $('<option />');
        $option.val(val);
        $option.text(val);
        $select.append($option);
      });
  }

  ['publisher', 'kind', 'status', 'location'].forEach(function (item) {
    add_options($('#book-register-' + item), Bibman.config.book[item].values);
  });
  ['purchaser', 'budget'].forEach(function (item) {
    add_options($('#purchase-frame-tex-' + item), Bibman.config.tex[item].values);
  });

  /** switch event for disability of label **/
  (function () {
    var DOM_checkbox = document.getElementById('purchase-frame-label-use-specified');
    var DOM_input = document.getElementById('purchase-frame-label');
    var $input = $(DOM_input);
    var disabled_value = $input.data('disabled-value');

    var on_change = function () {
      if (DOM_checkbox.checked) {
        DOM_input.disabled = false;
        $input.val($input.data('value'));
      }
      else {
        DOM_input.disabled = true;
        $input.data('value', $input.val());
        $input.val(disabled_value);
      }
    };

    $(DOM_checkbox).change(on_change);
  })();


  function collect_form_data($form) {
    var empty = false;
    $form.find('input,select').each(function () {
      empty = empty || (!$(this).data('ignore') && $(this).val() === '');
    });
    if (empty) {
      return null;
    }
    else {
      var data = {};
      $form.find('input,select').each(function() {
        var item = $(this).data('item');
        if (item) data[item] = $(this).val();
      });
      return data;
    }
  }


  /* purchase */
  var purchase = (function () {

    function download_tex(data) {
      var url = Bibman.API.ROOT + 'book-' + data.id + '.tex';
      var loc = window.location;
      var full_url = loc.protocol + '//' + loc.host + loc.pathname + url;

      $.fileDownload(url, {
        failCallback: function() {
          window.alert('ファイルのダウンロードに失敗しました．' + full_url + ' に再度アクセスするか，管理者に連絡してください．');
        },
        data: data
      });
    }

    var $frame = $('#purchase-frame');
    var hide_frame = function () {
      $frame.css('visibility', 'hidden');
    };
    var book_id;
    var $dfd;

    /* allocate label & download tex */
    $('#purchase-frame-ok').click(function () {
      var data = collect_form_data($('#purchase-frame'));

      if (data === null) {
        window.alert('未入力の項目があります．');
        return;
      }

      data.id = book_id;

      var success = function () {
        download_tex(data);
        $dfd.resolve();
        hide_frame();
      };
      var failure = function () {
        window.alert('ラベルの設定に失敗しました．管理者にお知らせください．');
        $dfd.reject();
      };

      if ($('#purchase-frame-label-use-specified').is(':checked')) {
        Bibman.API.edit_book({
          id: book_id,
          item: "label",
          /* TODO: If label is wanted to be empty, it shouldn't be checked */
          value: $('#purchase-frame-label').val()
        }).done(success).fail(failure);
      }
      else {
        Bibman.API.allocate_label(data).done(success).fail(failure);
      }
    });

    $('#purchase-frame-cancel').click(function () {
      $dfd.reject();
      hide_frame();
    });

    return function (bid) {
      $('#purchase-frame').find('input:text,select').each(function () {
        $(this).val('');
      });

      $('#purchase-frame-label-use-specified').checked = false;
      var $label = $('#purchase-frame-label');
      $label.val($label.data('disabled-value'));

      $frame.css('visibility', 'visible');

      book_id = bid;
      $dfd = $.Deferred();
      return $dfd;
    };
  })();

  /* book register */
  function register_event_handler(e, booklist, drawer, elements) {
    var data = collect_form_data($(e.target));
    if (data === null) {
      window.alert('未入力の項目があります．');
      return;
    }

    Bibman.API.register_book(data)
      .done(function(id) {
        if (data.status === Bibman.config.book.status.purchase) {
          purchase(id);
        }
        else {
          Bibman.API.search_book({ id: id }).done(function (data) {
            booklist.unshift_book(data);
            drawer.draw(0, booklist.count());
            elements.show();
          });
        }
      })
      .fail(function() {
        window.alert('入力に誤りがあるか，もしくは既に登録済みです．');
      });
  }

  /* wish-booklist */
  function remove_book_from_wish_book(id, booklist, elements, drawer) {
    booklist.remove(id);
    if (booklist.count() === 0) {
      elements.hide();
    }
    else {
      drawer.list();
    }
  }

  function set_purchase_event_handler(booklist, drawer, elements) {
    var may_purchase = function(target, val) {
      return $(target).data('item') === 'status' &&
        val === Bibman.config.book.status.purchase;
    };

    var booklistUI = drawer.booklistUI();

    booklistUI.on_complete_edit(function(e) {
      if (may_purchase(e.target, e.value) &&
          !window.confirm('購入が確定した本はほしい本リストから削除されます．よろしいですか？')) {
        e.prevent();
      }
    });

    booklistUI.on_succeed_in_edit(function(e) {
      var $target = $(e.target);
      if (may_purchase($target, e.value)) {

        var id = $target.parents('.book-item').data('book-id');

        purchase(id).done(function () {
          remove_book_from_wish_book(id, booklist, elements, drawer);
        });
      }
    });

  }

  function remove_event_handler($target, booklist, elements, drawer) {
    if (!window.confirm('ほしい本リストから削除します．よろしいですか？')) return;

    var id = $target.parents('.book-item').data('book-id');
    Bibman.API.remove_wishbook({ id: id })
      .done(function() {
        remove_book_from_wish_book(id, booklist, elements, drawer);
      })
      .fail(function() {
        window.alert('ほしい本の削除に失敗しました．');
      });
  }

  Bibman.API.wishbook().done(function(result) {
    var booklist = new Bibman.BookList(Bibman.user, { books: result });

    var $sort = $('#wishbook-sort');
    var $list = $('#wishbook-list');

    var drawer = new Bibman.BookList.UI.SortDrawer(
      booklist,
      { deny_lending: true, removable: true },
      { $list: $list, $sort: $sort }
    );

    $sort.change(function() { drawer.list(); });

    var elements = {
      show: function() { Bibman.UI.show($list, $sort); },
      hide: function() { Bibman.UI.hide($list, $sort); }
    };

    set_purchase_event_handler(booklist, drawer, elements);

    $list.click(function(e) {
      var $target = $(e.target);
      if ($target.hasClass('remove')) {
        remove_event_handler($target, booklist, elements, drawer);
        return false;
      }
    });

    $('#book-register-form').submit(function (e) {
      register_event_handler(e, booklist, drawer, elements);
      return false;
    });

    if (booklist.count() === 0) {
      elements.hide();
    }
    else {
      elements.show();
      drawer.list();
    }
  });

  /* Book Search by external API */
  function book_info(isbn) {
    return $.ajax({
      url: 'https://www.googleapis.com/books/v1/volumes',
      data: { q: 'isbn:' + isbn },
      type: 'GET',
      dataType: 'jsonp'
    });
  }

  function add_publisher_unless_exists($publisher, publisher) {
    var $dfd = $.Deferred();

    var found = false;
    $publisher.find('option').each(function() {
      found = found || $(this).val() === publisher;
    });
    if (found) {
      $dfd.resolve();
      return $dfd;
    }

    if (!window.confirm(
      "出版社 '" + publisher + "' は登録されていません．新しく登録しますか？(登録しない場合，書籍の登録もキャンセルされます．)"
    )) {
      return null;
    }

    Bibman.API.add({ item: "publisher", value: publisher })
      .done(function() {
        var $option = $('<option />');
        $option.val(publisher);
        $option.text(publisher);
        $publisher.append($option);

        $dfd.resolve();
      })
      .fail(function() {
        window.alert('出版社の登録に失敗しました．');
        $dfd.reject();
      });

    return $dfd;
  }

  $('#book-register-search').click(function(e) {
    var isbn = $('#book-register-isbn').val();
    if (isbn === '') return;
    book_info(isbn)
      .done(function (json) {
        if (json.totalItems !== 1) {
          window.alert('対応する書籍が見つかりませんでした．');
          return;
        }

        var volume_info = json.items[0].volumeInfo;
        var $publisher = $('#book-register-publisher');
        var $dfd = add_publisher_unless_exists($publisher, volume_info.publisher);
        if ($dfd !== null) {
          $dfd.done(function () {
            var year = volume_info.publishedDate.substring(0, 4);
            $publisher.val(volume_info.publisher);
            $('#book-register-title').val(volume_info.title);
            $('#book-register-author').val(volume_info.authors.join(', '));
            $('#book-register-publish-year').val(year);
          });
        }
      })
      .fail(function() {
        window.alert('書籍情報の取得に失敗しました．');
      });
  });
});

/* my page */
Bibman.init.load_callbacks.add(function() {

  function list_books(books, $list_block) {
    Bibman.collect_lendings_and_histories(books, function(result) {
      var booklist = new Bibman.BookList(Bibman.user, result);
      if (booklist.count() === 0) {
        $list_block.empty();
      }
      else {
        var drawer = new Bibman.BookList.UI.AllDrawer(
          booklist,
          $('#book-item-template'),
          $list_block
        );
        drawer.draw();
      }
    });
  }

  function update_my_lists() {
    Bibman.API.my_book()
      .done(function(mydata) {
        list_books(mydata.lending, $('#my-lending'));
        list_books(mydata.reservation, $('#my-reservation'));
        list_books(mydata.history, $('#my-history'));
      });
  }

  Bibman.API.lend_book.lending_callbacks.add(update_my_lists);
  update_my_lists();
});

/* logout */
Bibman.init.load_callbacks.add(function () {
  $('#logout').click(function () {
    var content_type = 'application/x-www-form-urlencoded; charset=UTF-8';
    Bibman.API.logout({}, { contentType: content_type })
      .always(function () {
        window.location = window.location.href.replace(/\/[^\/]+(?:\/#)?$/, '/');
      });
  });
});

/* swtich contents */
Bibman.switch_tab = function(id) {
  Bibman.UI.hide($('.contents'));
  Bibman.UI.show($('#' + id));
  window.location.hash = 'top-anchor';
  window.location.hash = '';
};

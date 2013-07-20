
// App.Init
App = Ember.Application.create({
  LOG_TRANSITIONS: true
});

App.initializer({
  name: "soundManager",
  initialize: function() {
    soundManager.setup({
      url: '/assets/javascripts/libs/soundmanager2_flash9.swf',
      flashVersion: 9, // optional: shiny features (default = 8)
      // optional: ignore Flash where possible, use 100% HTML5 mode
      // preferFlash: false,
      onready: function() {
      }
    });
  }
});


// App.Model
App.Store = DS.Store.extend({
  revision: 1
});

App.Song = DS.Model.extend({
  id:   DS.attr('number'),

  name: DS.attr('string'),
  album_name: DS.attr('string'),
  artist_name: DS.attr('string'),
  singer_names: DS.attr('string'),

  song_url:   DS.attr('string'),
  lyric_url:  DS.attr('string'),
  album_cover_url: DS.attr('string'),
  album_cover_large_url: function() {
    return this.get('album_cover_url').replace('2.jpg', '4.jpg')
  }.property('album_cover_url'),

  vote_up_count:   DS.attr('number'),

  created_at: DS.attr('date'),
  updated_at: DS.attr('date')

});




// App.Router
App.Router.map(function() {
  // put your routes here
  // this.resource('songs');
  this.resource('song', { path: '/songs/:song_id' });
});

App.SongRoute = Ember.Route.extend({
  model: function(params) {
    // return App.Song.find(359733);
    return App.Song.find(params.song_id);
  },
  setupController: function(controller, model) {
    controller.set('model', model);
  }
});


// App.Component
Ember.SoundPlayerManager = Ember.StateManager.extend({
  initialState: 'preparing',

  preparing: Ember.State.create({
    ready: function(manager, context) {
      manager.transitionTo('unloaded');
    }
  }),

  unloaded: Ember.State.create({
    loaded: function(manager, context) {
      manager.transitionTo('stopped');
    }
  }),

  stopped: Ember.State.create({
    play: function(manager, context) {
      manager.transitionTo('started.playing');
    }
  }),

  started: Ember.State.create({
    stop: function(manager, context) {
      manager.transitionTo('stopped');
    },

    paused: Ember.State.create({
      play: function(manager, context) {
        manager.transitionTo('playing');
      }
    }),

    playing: Ember.State.create({
      pause: function(manager, context) {
        manager.transitionTo('paused')
      }
    })
  })
});


Ember.MusicPlayer = Ember.View.extend({
  autoPlay: false,

  init: function() {
    var manager = Ember.SoundPlayerManager.create();
    var self = this;

    this.set("stateManager", manager);
    soundManager.onready(function() {
      manager.send('ready');
      self.loadSound();
    });

    this._super();
  },

  urlChanged: function() {
    this.soundObject.destruct();
    this.soundObject = undefined;
    this.get('stateManager').transitionTo('unloaded');
    this.loadSound();
  }.observes('url'),

  soundLoaded: function() {
    this.get('stateManager').send('loaded');
    this.set('position', 0);
    this.set('duration', this.get('sound').duration);
    if (this.get('autoPlay')) { this.play() };
  },

  loadSound: function() {
    var self = this;

    if (!this.get('isStopped')) {
      this.stop();
    }
    if (!this.soundObject) {
      this.soundObject = soundManager.createSound({
        id: 'sound',
        url: this.get('url'),
        autoLoad: true,
        autoPlay: false,
        onload: function() { self.soundLoaded(); },
        whileplaying: function() { self.tick(); },
        onfinish: function() { self.finish(); }
      });
    }
  },

  sound: function() {
    this.loadSound();
    return this.soundObject;
  }.property('url'),

  play: function() {
    if (this.get('isStopped')) {
      this.get('sound').play();
    } else {
      this.get('sound').resume();
    }
    this.get('stateManager').send('play');
  },

  pause: function() {
    this.get('stateManager').send('pause');
    this.get('sound').pause();
  },

  toggle: function() {
    if (this.get('isPlaying')) {
      this.pause();
    } else {
      this.play();
    }
  },

  stop: function() {
    this.get('stateManager').send('stop');
    this.get('sound').stop();
    this.set('position', 0);
  },

  finish: function() {
    this.get('stateManager').send('stop');
    // this.set('position', 0);
  },

  tick: function() {
    this.set('position', this.get('sound').position);
  },

  isLoading: function() {
    return this.get('stateManager.currentState.name') === 'unloaded';
  }.property('stateManager.currentState'),

  isStopped: function() {
    return !/^started\./.test(this.get('stateManager.currentState.path'));
  }.property('stateManager.currentState'),

  isPlaying: function() {
    return this.get('stateManager.currentState.name') === 'playing'
  }.property('stateManager.currentState')
});

Ember.Playlist = Ember.View.extend({
  mode: 'loop',  // loop, shuffle, repeatOne
  playlist: [],
  sequenceList: function() {
    var list = this.get('playlist');
    switch (this.get('mode')) {
    case 'shuffle':
      if (list.length > 1) {
        for (var i = list.length - 1; i > 0; i--) {
          var j = Math.floor(Math.random() * (i + 1));
          var temp = list[i];
          list[i] = list[j];
          list[j] = temp;
        };
      };
      return list;
      break;
    case 'repeatOne':
      return [this.get('nowPlaying')];
      break;
    case 'loop':
      return list;
      break;
    };

    return list;
  }.property('mode', 'playlist'),

  nowPlaying: function() {
    var cursor = this.get('cursor');
    var list   = this.get('sequenceList');
    if (typeof cursor == 'undefined') {
      return list[0];
    } else {
      return list[cursor];
    }
  }.property('cursor'),

  next: function(step) {
    var list = this.get('sequenceList');
    var cursor = this.get('cursor');
    var length = list.length();
    if (typeof cursor !== 'number') { cursor = -1 }
    if (typeof step   !== 'number') { step   = 1  }
    cursor = cursor + step;
    if (cursor >= length) {
      cursor = (cursor+1)%length - 1;
    } else if (cursor < 0){
      cursor = cursor%-length + length;
    };

    this.set('cursor', cursor);
    return list[cursor];
  },

  perv: function() {
    return this.next(-1);
  }
});

App.MusicPlayer = Ember.MusicPlayer.extend({
  templateName: 'musicplayer',
  classNames: ['musicplayer'],
  classNameBindings: ['isPlaying'],
  attributeBindings: ['style'],

  progressBarStyle: function() {
    precent = this.get('position')/this.get('duration')*100;
    return "width: "+precent+"%;";
  }.property('position'),

  style: function() {
    return "background-image: url("+this.get('info').get('album_cover_large_url')+")";
  }.property('info'),

  playbackText: function() {
    if (this.get('isPlaying')) {
      return 'Pause';
    } else {
      return 'Play';
    }
  }.property('isPlaying'),

  click: function(e) {
    var self = $(e.target);
    if(self.is('.progress')) {
      if(!this.get('isPlaying')) { this.play() }
      this.get('sound').setPosition(this.get('duration') * e.offsetX / self.width())
    }
  }
});


(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);throw new Error("Cannot find module '"+o+"'")}var f=n[o]={exports:{}};t[o][0].call(f.exports,function(e){var n=t[o][1][e];return s(n?n:e)},f,f.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({"/Users/davidkaneda/Dropbox (Personal)/Sites/buckets/node_modules/buckets-location/client.coffee":[function(require,module,exports){
if (typeof bkts !== "undefined" && bkts !== null) {
  bkts.plugin('location', {
    name: 'Location',
    inputView: require('./views/map'),
    settingsView: "<div class=\"checkbox\">\n  <label>\n    <input type=\"checkbox\" name=\"useTitleForInput\"> Use entry title as input\n  </label>\n</div>\n\n<div class=\"form-group\">\n  <label for=\"inputPlaceholder\">Placeholder text</label>\n  <input type=\"text\" name=\"placeholder\" id=\"inputPlaceholder\" class=\"form-control\" value=\"Address, Zip, City, or Region\">\n</div>"
  });
}



},{"./views/map":"/Users/davidkaneda/Dropbox (Personal)/Sites/buckets/node_modules/buckets-location/views/map.coffee"}],"/Users/davidkaneda/Dropbox (Personal)/Sites/buckets/node_modules/buckets-location/templates/map.hbs":[function(require,module,exports){
// hbsfy compiled Handlebars template
var HandlebarsCompiler = require('hbsfy/runtime');
module.exports = HandlebarsCompiler.template({"compiler":[6,">= 2.0.0-beta.1"],"main":function(depth0,helpers,partials,data) {
  var stack1, helper, functionType="function", helperMissing=helpers.helperMissing, escapeExpression=this.escapeExpression;
  return "<label>"
    + escapeExpression(((helper = (helper = helpers.name || (depth0 != null ? depth0.name : depth0)) != null ? helper : helperMissing),(typeof helper === functionType ? helper.call(depth0, {"name":"name","hash":{},"data":data}) : helper)))
    + "</label>\n\n<div class=\"form-group\">\n  <div class=\"map-container\">\n    <div class=\"mapInput\">\n      "
    + escapeExpression(((helpers.input || (depth0 && depth0.input) || helperMissing).call(depth0, "location", ((stack1 = (depth0 != null ? depth0.value : depth0)) != null ? stack1.name : stack1), {"name":"input","hash":{
    'placeholder': (((stack1 = (depth0 != null ? depth0.settings : depth0)) != null ? stack1.placeholder : stack1))
  },"data":data})))
    + "\n      <a href=\"#getCurrent\" title=\"Use your current location\" class=\"btn btn-link btn-icon btn-icon-small\">"
    + escapeExpression(((helpers.icon || (depth0 && depth0.icon) || helperMissing).call(depth0, "location-arrow", {"name":"icon","hash":{},"data":data})))
    + "</a>\n    </div>\n    <div class=\"map\"></div>\n  </div>\n</div>\n";
},"useData":true});

},{"hbsfy/runtime":"pu95bm"}],"/Users/davidkaneda/Dropbox (Personal)/Sites/buckets/node_modules/buckets-location/views/map.coffee":[function(require,module,exports){
var Buckets, MapInputView, tpl, _,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Buckets = require('buckets');

_ = Buckets._;

tpl = require('./../templates/map');

module.exports = MapInputView = (function(_super) {
  __extends(MapInputView, _super);

  function MapInputView() {
    this.updateLocationText = __bind(this.updateLocationText, this);
    this.mapsLoaded = __bind(this.mapsLoaded, this);
    return MapInputView.__super__.constructor.apply(this, arguments);
  }

  MapInputView.prototype.template = tpl;

  MapInputView.prototype.defaultLocation = {
    lat: 39.952335,
    lng: -75.163789
  };

  MapInputView.prototype.events = {
    'change [name="location"]': 'updateLocationText',
    'keydown [name="location"]': 'keyDownLocation',
    'click [href="#getCurrent"]': 'clickGetCurrent',
    'change .simpleLocation': 'updateSimpleLocation'
  };

  MapInputView.prototype.getTemplateData = function() {
    return _.extend(MapInputView.__super__.getTemplateData.apply(this, arguments), {
      googleMapsAvailable: (typeof google !== "undefined" && google !== null ? google.maps : void 0) != null,
      lat: this.lat,
      lng: this.lng
    });
  };

  MapInputView.prototype.initialize = function() {
    MapInputView.__super__.initialize.apply(this, arguments);
    return Modernizr.load({
      test: window.google != null,
      nope: 'https://www.google.com/jsapi',
      complete: (function(_this) {
        return function() {
          return _.defer(function() {
            if (window.google != null) {
              if (Buckets.mediator.mapsLoaded == null) {
                Buckets.mediator.mapsLoaded = new $.Deferred;
                google.load('maps', '3', {
                  other_params: 'sensor=false',
                  callback: function() {
                    return Buckets.mediator.mapsLoaded.resolve();
                  }
                });
              }
              return Buckets.mediator.mapsLoaded.done(_this.mapsLoaded);
            } else {
              console.warn('Could not load Google API.', window.google);
              return _this.render();
            }
          });
        };
      })(this)
    });
  };

  MapInputView.prototype.render = function() {
    var location, val;
    val = this.model.get('value');
    if ((val != null ? val.lat : void 0) && val.lng) {
      location = {
        lat: val.lat,
        lng: val.lng
      };
    } else {
      location = this.defaultLocation;
    }
    this.updatePosition(location.lat, location.lng);
    MapInputView.__super__.render.apply(this, arguments);
    return this.$map = this.$('.map');
  };

  MapInputView.prototype.mapsLoaded = function() {
    this.render();
    if (this.readonly) {
      return this.$map.append("<img src=\"//maps.googleapis.com/maps/api/staticmap?center=" + this.lat + "," + this.lng + "&zoom=14&size=230x140&markers=" + this.lat + "," + this.lng + "&sensor=false&scale=2\">");
    } else {
      google.maps.visualRefresh = true;
      this.map = new google.maps.Map(this.$map.get(0), {
        zoom: 14,
        mapTypeId: google.maps.MapTypeId.ROADMAP,
        disableDoubleClickZoom: true,
        streetViewControl: false,
        scrollwheel: false,
        mapTypeControl: false,
        styles: [
          {
            featureType: 'poi',
            elementType: 'labels',
            stylers: [
              {
                visibility: 'off'
              }
            ]
          }
        ]
      });
      this.geocoder = new google.maps.Geocoder;
      return this.updatePosition(this.lat, this.lng);
    }
  };

  MapInputView.prototype.updateSimpleLocation = function() {
    return this.updatePosition(this.$('[name="lat"]').val(), this.$('[name="lng"]').val());
  };

  MapInputView.prototype.updatePosition = function(lat, lng) {
    var hadMarker;
    this.lat = parseFloat(lat);
    this.lng = parseFloat(lng);
    if (this.map) {
      if (this.marker) {
        hadMarker = true;
        this.marker.setMap(null);
        delete this.marker;
      }
      this.map.panTo(new google.maps.LatLng(lat, lng));
      return this.marker = new google.maps.Marker({
        position: new google.maps.LatLng(lat, lng),
        map: this.map,
        animation: !hadMarker ? google.maps.Animation.DROP : void 0
      });
    }
  };

  MapInputView.prototype.updateLocationText = function(e) {
    var val;
    val = $(e.target).val();
    if (val !== this.lastValue) {
      return this.geocoder.geocode({
        address: $(e.target).val()
      }, (function(_this) {
        return function(results, status) {
          var loc;
          if ((results != null ? results[0] : void 0) && status === 'OK') {
            loc = results[0].geometry.location;
            _this.updatePosition(loc.lat(), loc.lng());
            _this.model.set(results);
            if (_this.usingGeolocation === true) {
              val = results[0].formatted_address;
              $(e.currentTarget).val(val);
              _this.usingGeolocation = false;
            }
            return _this.lastValue = val;
          }
        };
      })(this));
    }
  };

  MapInputView.prototype.keyDownLocation = function(e) {
    if (e.keyCode === 13) {
      e.preventDefault();
      return this.updateLocationText(e);
    }
  };

  MapInputView.prototype.getValue = function() {
    if ((typeof google !== "undefined" && google !== null ? google.maps : void 0) == null) {
      this.updateSimpleLocation();
    }
    if (this.isDefaultLocation()) {
      return null;
    } else {
      return {
        lat: this.lat,
        lng: this.lng,
        name: this.$('input[name="location"]').val()
      };
    }
  };

  MapInputView.prototype.clickGetCurrent = function(e) {
    var $el, $input, enableInput, fallbackCachedValue, _ref;
    $el = $(e.currentTarget);
    $input = this.$('input[name="location"]');
    fallbackCachedValue = $input.val();
    e.preventDefault();
    enableInput = function() {
      $input.prop('disabled', false);
      return $el.removeClass('loadingPulse');
    };
    if (navigator.geolocation != null) {
      $input.prop('disabled', true);
      $el.addClass('loadingPulse');
      $input.val('Looking up location…');
      return (_ref = navigator.geolocation) != null ? _ref.getCurrentPosition((function(_this) {
        return function(pos) {
          if (pos != null ? pos.coords : void 0) {
            _this.usingGeolocation = true;
            $input.val("" + pos.coords.latitude + ", " + pos.coords.longitude).trigger('change');
          }
          return enableInput();
        };
      })(this), function() {
        $input.val(fallbackCachedValue);
        return enableInput();
      }) : void 0;
    }
  };

  MapInputView.prototype.isDefaultLocation = function() {
    return this.lat === this.defaultLocation.lat && this.lng === this.defaultLocation.lng;
  };

  MapInputView.prototype.dispose = function() {
    var _ref;
    if (((typeof google !== "undefined" && google !== null ? (_ref = google.maps) != null ? _ref.event : void 0 : void 0) != null) && !this.disposed) {
      if (this.marker != null) {
        this.marker.setMap(null);
      }
      google.maps.event.clearInstanceListeners(window);
      google.maps.event.clearInstanceListeners(document);
      google.maps.event.clearInstanceListeners(this.$map.get(0));
    }
    return MapInputView.__super__.dispose.apply(this, arguments);
  };

  return MapInputView;

})(Buckets.View);



},{"./../templates/map":"/Users/davidkaneda/Dropbox (Personal)/Sites/buckets/node_modules/buckets-location/templates/map.hbs","buckets":false}]},{},["/Users/davidkaneda/Dropbox (Personal)/Sites/buckets/node_modules/buckets-location/client.coffee"]);
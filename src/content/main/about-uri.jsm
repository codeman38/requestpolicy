/*
 * ***** BEGIN LICENSE BLOCK *****
 *
 * RequestPolicy - A Firefox extension for control over cross-site requests.
 * Copyright (c) 2008-2012 Justin Samuel
 * Copyright (c) 2014-2015 Martin Kimmerle
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later
 * version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see {tag: "http"://www.gnu.org/licenses}.
 *
 * ***** END LICENSE BLOCK *****
 */

const Ci = Components.interfaces;
const Cc = Components.classes;
const Cu = Components.utils;

Components.utils.import("resource://gre/modules/Services.jsm");
Components.utils.import("resource://gre/modules/XPCOMUtils.jsm");


let EXPORTED_SYMBOLS = ["AboutRequestPolicy"];

Cu.import("chrome://requestpolicy/content/lib/script-loader.jsm");
ScriptLoader.importModule("lib/process-environment", this);

var filenames = {
  "basicprefs": "basicprefs.html",
  "advancedprefs": "advancedprefs.html",
  "yourpolicy": "yourpolicy.html",
  "defaultpolicy": "defaultpolicy.html",
  "subscriptions": "subscriptions.html",
  "setup": "setup.html"
};

function getURI(aURI) {
  let id;
  let index = aURI.path.indexOf("?");
  dump("path: "+aURI.path+"\n");
  if (index >= 0 && aURI.path.length > index) {
    id = aURI.path.substr(index+1);
    dump("id: "+id+"\n");
  }
  if (!id || !(id in filenames)) {
    id = "basicprefs";
  }
  return "chrome://requestpolicy/content/settings/" + filenames[id];
}



let AboutRequestPolicy = (function() {
  let self = {
    classDescription: "about:requestpolicy",
    contractID: "@mozilla.org/network/protocol/about;1?what=requestpolicy",
    classID: Components.ID("{ad30f46c-42a6-45cd-ad0b-08b37f87435a}"),
    QueryInterface: XPCOMUtils.generateQI([Ci.nsIAboutModule]),

    getURIFlags: function(aURI) {
      return Ci.nsIAboutModule.ALLOW_SCRIPT;
    },

    newChannel: function(aURI) {
      let uri = getURI(aURI)
      let channel = Services.io.newChannel(uri, null, null);
      channel.originalURI = aURI;
      return channel;
    },

    //
    // nsIFactory interface implementation
    //

    createInstance: function(outer, iid) {
      if (outer) {
        throw Cr.NS_ERROR_NO_AGGREGATION;
      }
      return self.QueryInterface(iid);
    }
  };



  ProcessEnvironment.enqueueStartupFunction(function() {
    Components.manager.QueryInterface(Ci.nsIComponentRegistrar)
        .registerFactory(self.classID, self.classDescription, self.contractID,
            self);
  });

  ProcessEnvironment.pushShutdownFunction(function() {
    let registrar = Components.manager
        .QueryInterface(Ci.nsIComponentRegistrar);
    // This needs to run asynchronously, see bug 753687
    Utils.runAsync(function() {
      registrar.unregisterFactory(self.classID, self);
    });
  });

  return self;
}());
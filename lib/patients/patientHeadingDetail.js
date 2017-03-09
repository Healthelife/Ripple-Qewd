/*

 ----------------------------------------------------------------------------
 | qewd-ripple: QEWD-based Middle Tier for Ripple OSI                       |
 |                                                                          |
 | Copyright (c) 2016-17 Ripple Foundation Community Interest Company       |
 | All rights reserved.                                                     |
 |                                                                          |
 | http://rippleosi.org                                                     |
 | Email: code.custodian@rippleosi.org                                      |
 |                                                                          |
 | Author: Rob Tweed, M/Gateway Developments Ltd                            |
 |                                                                          |
 | Licensed under the Apache License, Version 2.0 (the "License");          |
 | you may not use this file except in compliance with the License.         |
 | You may obtain a copy of the License at                                  |
 |                                                                          |
 |     http://www.apache.org/licenses/LICENSE-2.0                           |
 |                                                                          |
 | Unless required by applicable law or agreed to in writing, software      |
 | distributed under the License is distributed on an "AS IS" BASIS,        |
 | WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. |
 | See the License for the specific language governing permissions and      |
 |  limitations under the License.                                          |
 ----------------------------------------------------------------------------

  8 March 2017

*/

var openEHR = require('../openEHR/openEHR');
var headingsLib = require('../headings/headings');
var headings = headingsLib.headings;

function patientHeadingDetail(patientId, headingName, sourceId, session) {

  if (!headings[headingName]) {
    console.log('*** ' + heading + ' has not yet been added to middle-tier processing');
    return {error: headingName + ' has not yet been added to middle-tier processing'};
  }

  var heading = headings[headingName].name;

  console.log('*** patientHeadingDetail - heading = ' + heading + '; session ' + session.id);

  var patient = session.data.$(['patients', patientId]);
  //var patient = new this.documentStore.DocumentNode('ripplePatients', [patientId]);
  var nhsNo = patientId;
  var openEHRId = patient.$('openEHRId').value
  if (openEHRId !== '') nhsNo = openEHRId;

  var patientHeadingIndex = patient.$(['headingIndex', heading]);
  //console.log('patientHeadingIndex for patient ' + patientId + ': ' + JSON.stringify(patientHeadingIndex.getDocument()));
  //var patientHeadingIndex = new this.documentStore.DocumentNode('ripplePatients', [patientId, 'headingIndex', headings[heading].name]);

  /*
    should always exist in cache by this point!

  if (!patientHeadingIndex.exists) {
    
    // go and fetch it!

    var q = this;
    console.log('*** heading ' + heading + ' needs to be fetched!')
    openEHR.startSessions(function(openEHRSessions) {
      //console.log('*** sessions: ' + JSON.stringify(sessions));
      openEHR.mapNHSNo(nhsNo, openEHRSessions, function() {
        //console.log('*** NHS no mapped');
        getSelectedHeading(patientId, heading, session, openEHRSessions, function() {
          // now try again!
          //console.log('**** trying again!');
          openEHR.stopSessions(openEHRSessions);
          patientHeadingDetail.call(q, patientId, heading, sourceId, session);
        });
      });
    });
    return;
  }
  */

  //console.log('**** sourceId: ' + sourceId);
  var indexSource = patientHeadingIndex.$(sourceId);
  if (!indexSource.exists) {
    return {error: 'Invalid sourceId ' + sourceId + ' for patient ' + nhsNo + ' / heading ' + heading};
  }
  var index = indexSource.getDocument();

  if (!index.recNo || index.recNo === '') {
    return {error: 'Unable to use the index to sourceId ' + sourceId + ' for patient ' + nhsNo + ' / heading ' + heading + ': recNo is missing'};
  }

  var patientHeading = patient.$(['headings', heading, index.host, index.recNo]);
  //var patientHeading = new this.documentStore.DocumentNode('ripplePatients', [patientId, 'headings', headings[heading].name, index.host, index.recNo]);

  var result = {
    sourceId: sourceId,
    source: openEHR.servers[index.host].sourceName
  };
  var record;

  if (typeof patientHeading === 'undefined') {
    record = {};
  }
  else {
    record = patientHeading.getDocument();
  }
  //console.log('*** record: ' + JSON.stringify(record));

  for (var name in headings[heading].fieldMap) {
    if (typeof headings[heading].fieldMap[name] === 'function') {
      result[name] = headings[heading].fieldMap[name](record, index.host);
    }
    else {
      result[name] = record[headings[heading].fieldMap[name]];
    }
  }
  return result;
}

module.exports = patientHeadingDetail;

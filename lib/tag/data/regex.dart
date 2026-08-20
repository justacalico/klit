// SPDX-License-Identifier: AGPL-3.0

RegExp poolRegex() => RegExp(r'^pool:(?<id>\d+)$');

RegExp favRegex(String username) => RegExp(r'^fav:' + username + r'$');

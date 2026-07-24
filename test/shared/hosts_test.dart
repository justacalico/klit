import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:kilt/shared/data/hosts.dart';

void main() {
  group('getHostIcon', () {
    test('returns mastodon icon for mastodon.art', () {
      expect(getHostIcon('https://mastodon.art/@user'), FontAwesomeIcons.mastodon);
    });

    test('returns mastodon icon for baraag.net', () {
      expect(getHostIcon('https://baraag.net/test'), FontAwesomeIcons.mastodon);
    });

    test('returns discord icon for discord.com', () {
      expect(getHostIcon('https://discord.com'), FontAwesomeIcons.discord);
    });

    test('returns discord icon for cdn.discordapp.com', () {
      expect(
        getHostIcon('https://cdn.discordapp.com/attachments/123'),
        FontAwesomeIcons.discord,
      );
    });

    test('returns twitter icon for twitter.com', () {
      expect(getHostIcon('https://twitter.com/user'), FontAwesomeIcons.twitter);
    });

    test('returns twitter icon for twimg.com subdomain', () {
      expect(getHostIcon('https://pbs.twimg.com/image'), FontAwesomeIcons.twitter);
    });

    test('returns x twitter icon for x.com', () {
      expect(getHostIcon('https://x.com/user'), FontAwesomeIcons.xTwitter);
    });

    test('returns pixiv icon for pixiv.net', () {
      expect(getHostIcon('https://pixiv.net/art/123'), FontAwesomeIcons.p);
    });

    test('returns pixiv icon for i.pximg.net', () {
      expect(getHostIcon('https://i.pximg.net/img/'), FontAwesomeIcons.p);
    });

    test('returns paw icon for furaffinity.net', () {
      expect(getHostIcon('https://furaffinity.net/view/123'), FontAwesomeIcons.paw);
    });

    test('returns reddit icon for reddit.com', () {
      expect(getHostIcon('https://reddit.com/r/test'), FontAwesomeIcons.redditAlien);
    });

    test('returns reddit icon for i.redd.it', () {
      expect(getHostIcon('https://i.redd.it/abc'), FontAwesomeIcons.redditAlien);
    });

    test('returns tumblr icon for tumblr.com', () {
      expect(getHostIcon('https://tumblr.com/blog'), FontAwesomeIcons.tumblr);
    });

    test('returns bluesky icon for bsky.app', () {
      expect(getHostIcon('https://bsky.app/profile'), FontAwesomeIcons.bluesky);
    });

    test('returns deviantart icon for deviantart subdomain', () {
      expect(
        getHostIcon('https://something.deviantart.com/art'),
        FontAwesomeIcons.deviantart,
      );
    });

    test('returns null for unknown host', () {
      expect(getHostIcon('https://example.com'), isNull);
    });

    test('returns null for another unknown host', () {
      expect(getHostIcon('https://some-random-site.org'), isNull);
    });

    test('returns null for invalid URL', () {
      expect(getHostIcon('http://['), isNull);
    });

    test('returns null for invalid port', () {
      expect(getHostIcon('http://example.com:abc'), isNull);
    });

    test('matches partial host pattern for fbcdn.net', () {
      expect(
        getHostIcon('https://scontent.fbcdn.net/image'),
        FontAwesomeIcons.facebookF,
      );
    });

    test('matches partial host pattern for bsky.network', () {
      expect(
        getHostIcon('https://host.bsky.network/x'),
        FontAwesomeIcons.bluesky,
      );
    });

    test('does not match apex domain for dot-prefixed patterns', () {
      expect(getHostIcon('https://fbcdn.net'), isNull);
    });
  });
}

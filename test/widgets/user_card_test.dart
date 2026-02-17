import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';

import 'package:my_circle\widgets\social\user_card.dart';
import 'package:my_circle\models\social_user.dart';
import 'package:my_circle\providers\social_provider.dart';

@GenerateMocks([VoidCallback, SocialProvider])
import 'user_card_test.mocks.dart';

void main() {
  group('UserCard Widget Tests', () {
    late SocialUser testUser;
    late MockVoidCallback mockOnTap;
    late MockVoidCallback mockOnFollow;
    late MockSocialProvider mockSocialProvider;

    setUp(() {
      mockOnTap = MockVoidCallback();
      mockOnFollow = MockVoidCallback();
      mockSocialProvider = MockSocialProvider();
      
      testUser = SocialUser(
        id: '1',
        username: 'testuser',
        displayName: 'Test User',
        bio: 'This is a test user bio',
        avatarUrl: 'https://example.com/avatar.jpg',
        followersCount: 1000,
        followingCount: 500,
        isVerified: true,
        isOnline: true,
        lastSeen: DateTime.now(),
      );
    });

    Widget createWidgetUnderTest({
      SocialUser? user,
      VoidCallback? onTap,
      VoidCallback? onFollow,
      bool showFollowButton = true,
      double? width,
      double? height,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<SocialProvider>(
            create: (_) => mockSocialProvider,
            child: UserCard(
              user: user ?? testUser,
              onTap: onTap ?? mockOnTap.call,
              onFollow: onFollow ?? mockOnFollow.call,
              showFollowButton: showFollowButton,
              width: width,
              height: height,
            ),
          ),
        ),
      );
    }

    testWidgets('should display user information correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('@testuser'), findsOneWidget);
      expect(find.text('This is a test user bio'), findsOneWidget);
    });

    testWidgets('should display follower and following counts', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('1000'), findsOneWidget); // Followers
      expect(find.text('500'), findsOneWidget); // Following
    });

    testWidgets('should display verified badge when user is verified', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byIcon(Icons.verified), findsOneWidget);
    });

    testWidgets('should not display verified badge when user is not verified', (WidgetTester tester) async {
      final unverifiedUser = SocialUser(
        id: '2',
        username: 'unverified',
        displayName: 'Unverified User',
        bio: 'Not verified user',
        avatarUrl: 'https://example.com/avatar2.jpg',
        followersCount: 100,
        followingCount: 50,
        isVerified: false,
        isOnline: false,
        lastSeen: DateTime.now(),
      );

      await tester.pumpWidget(createWidgetUnderTest(user: unverifiedUser));

      expect(find.byIcon(Icons.verified), findsNothing);
    });

    testWidgets('should display online indicator when user is online', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byIcon(Icons.circle), findsOneWidget);
    });

    testWidgets('should not display online indicator when user is offline', (WidgetTester tester) async {
      final offlineUser = SocialUser(
        id: '3',
        username: 'offlineuser',
        displayName: 'Offline User',
        bio: 'Offline user bio',
        avatarUrl: 'https://example.com/avatar3.jpg',
        followersCount: 200,
        followingCount: 100,
        isVerified: false,
        isOnline: false,
        lastSeen: DateTime.now().subtract(const Duration(hours: 1)),
      );

      await tester.pumpWidget(createWidgetUnderTest(user: offlineUser));

      expect(find.byIcon(Icons.circle), findsNothing);
    });

    testWidgets('should display follow button when showFollowButton is true', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(showFollowButton: true));

      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('should not display follow button when showFollowButton is false', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(showFollowButton: false));

      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('should call onTap when card is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.byType(Card));
      await tester.pump();

      verify(mockOnTap.call()).called(1);
    });

    testWidgets('should call onFollow when follow button is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(showFollowButton: true));

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      verify(mockOnFollow.call()).called(1);
    });

    testWidgets('should display avatar image', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(CircleAvatar), findsOneWidget);
    });

    testWidgets('should handle missing avatar gracefully', (WidgetTester tester) async {
      final userWithoutAvatar = SocialUser(
        id: '4',
        username: 'noavatar',
        displayName: 'No Avatar User',
        bio: 'User without avatar',
        avatarUrl: null,
        followersCount: 50,
        followingCount: 25,
        isVerified: false,
        isOnline: true,
        lastSeen: DateTime.now(),
      );

      await tester.pumpWidget(createWidgetUnderTest(user: userWithoutAvatar));

      final circleAvatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
      expect(circleAvatar.backgroundColor, isA<Color>());
      expect(circleAvatar.child, isA<Text>());
    });

    testWidgets('should apply custom width and height', (WidgetTester tester) async {
      const customWidth = 300.0;
      const customHeight = 150.0;

      await tester.pumpWidget(createWidgetUnderTest(
        width: customWidth,
        height: customHeight,
      ));

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.width, customWidth);
      expect(sizedBox.height, customHeight);
    });

    testWidgets('should display formatted follower counts', (WidgetTester tester) async {
      final popularUser = SocialUser(
        id: '5',
        username: 'popular',
        displayName: 'Popular User',
        bio: 'Very popular user',
        avatarUrl: 'https://example.com/avatar5.jpg',
        followersCount: 1500000,
        followingCount: 500,
        isVerified: true,
        isOnline: true,
        lastSeen: DateTime.now(),
      );

      await tester.pumpWidget(createWidgetUnderTest(user: popularUser));

      expect(find.text('1.5M'), findsOneWidget); // Followers formatted
      expect(find.text('500'), findsOneWidget); // Following not formatted
    });

    testWidgets('should handle empty bio gracefully', (WidgetTester tester) async {
      final userWithoutBio = SocialUser(
        id: '6',
        username: 'nobio',
        displayName: 'No Bio User',
        bio: '',
        avatarUrl: 'https://example.com/avatar6.jpg',
        followersCount: 100,
        followingCount: 50,
        isVerified: false,
        isOnline: false,
        lastSeen: DateTime.now(),
      );

      await tester.pumpWidget(createWidgetUnderTest(user: userWithoutBio));

      expect(find.text('No Bio User'), findsOneWidget);
      expect(find.text('@nobio'), findsOneWidget);
      // Bio should not be displayed or should be empty
    });

    testWidgets('should handle long usernames gracefully', (WidgetTester tester) async {
      final longUsernameUser = SocialUser(
        id: '7',
        username: 'verylongusernamethatshouldbetruncated',
        displayName: 'Long Username User',
        bio: 'User with long username',
        avatarUrl: 'https://example.com/avatar7.jpg',
        followersCount: 100,
        followingCount: 50,
        isVerified: false,
        isOnline: true,
        lastSeen: DateTime.now(),
      );

      await tester.pumpWidget(createWidgetUnderTest(user: longUsernameUser));

      final usernameText = tester.widget<Text>(find.textContaining('@verylongusernamethatshouldbetruncated'));
      expect(usernameText.maxLines, 1);
      expect(usernameText.overflow, TextOverflow.ellipsis);
    });

    testWidgets('should have correct card properties', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final card = tester.widget<Card>(find.byType(Card));
      expect(card.elevation, 2.0);
      expect(card.shape, isA<RoundedRectangleBorder>());
    });

    testWidgets('should wrap content in InkWell for tap feedback', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(InkWell), findsOneWidget);
    });

    testWidgets('should display follow button with correct text', (WidgetTester tester) async {
      when(mockSocialProvider.isFollowing(testUser.id)).thenReturn(false);
      
      await tester.pumpWidget(createWidgetUnderTest(showFollowButton: true));

      expect(find.text('Follow'), findsOneWidget);
    });

    testWidgets('should display following button when already following', (WidgetTester tester) async {
      when(mockSocialProvider.isFollowing(testUser.id)).thenReturn(true);
      
      await tester.pumpWidget(createWidgetUnderTest(showFollowButton: true));

      expect(find.text('Following'), findsOneWidget);
    });

    testWidgets('should handle null onFollow gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        showFollowButton: true,
        onFollow: null,
      ));

      expect(find.byType(ElevatedButton), findsOneWidget);
      
      // Tapping should not throw an exception
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
    });

    testWidgets('should handle rapid tap interactions', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Rapid taps
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.byType(Card));
        await tester.pump();
      }

      verify(mockOnTap.call()).called(5);
    });

    testWidgets('should handle rapid follow interactions', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(showFollowButton: true));

      // Rapid follow taps
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();
      }

      verify(mockOnFollow.call()).called(3);
    });

    testWidgets('should display follower and following labels', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Followers'), findsOneWidget);
      expect(find.text('Following'), findsOneWidget);
    });

    testWidgets('should display online status with correct color', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final onlineIcon = tester.widget<Icon>(find.byIcon(Icons.circle));
      expect(onlineIcon.color, Colors.green);
    });

    testWidgets('should display verified badge with correct color', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final verifiedIcon = tester.widget<Icon>(find.byIcon(Icons.verified));
      expect(verifiedIcon.color, Colors.blue);
    });

    testWidgets('should work without Provider context', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserCard(
              user: testUser,
              onTap: mockOnTap.call,
              onFollow: mockOnFollow.call,
              showFollowButton: false, // Disable follow button to avoid Provider dependency
            ),
          ),
        ),
      );

      expect(find.byType(UserCard), findsOneWidget);
      expect(find.text('Test User'), findsOneWidget);
    });
  });
}

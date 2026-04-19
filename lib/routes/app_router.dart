import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/teacher/teacher_shell.dart';
import '../screens/teacher/teacher_dashboard.dart';
import '../screens/teacher/teacher_courses_screen.dart';
import '../screens/teacher/teacher_assignments_screen.dart';
import '../screens/teacher/create_assignment_screen.dart';
import '../screens/teacher/assignment_detail_screen.dart';
import '../screens/teacher/teacher_students_screen.dart';
import '../screens/teacher/teacher_analytics_screen.dart';
import '../screens/teacher/teacher_grades_screen.dart';
import '../screens/student/student_shell.dart';
import '../screens/student/student_dashboard.dart';
import '../screens/student/student_courses_screen.dart';
import '../screens/student/student_assignments_screen.dart';
import '../screens/student/student_assignment_detail_screen.dart';
import '../screens/student/student_grades_screen.dart';
import '../screens/student/student_analytics_screen.dart';
import '../screens/shared/notifications_screen.dart';
import '../screens/shared/chat_list_screen.dart';
import '../screens/shared/chat_screen.dart';
import '../screens/shared/profile_screen.dart';
import '../screens/shared/settings_screen.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _teacherShellKey = GlobalKey<NavigatorState>();
  static final _studentShellKey = GlobalKey<NavigatorState>();

  static GoRouter router(AuthProvider authProvider) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/splash',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final isLoggedIn = authProvider.isAuthenticated;
        final isLoading = authProvider.isLoading;
        final path = state.uri.path;

        if (isLoading && path == '/splash') return null;
        if (path == '/splash') return null;

        if (!isLoggedIn) return '/login';

        if (path == '/login') {
          return authProvider.isTeacher ? '/teacher' : '/student';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),

        // Teacher Shell
        ShellRoute(
          navigatorKey: _teacherShellKey,
          builder: (context, state, child) => TeacherShell(child: child),
          routes: [
            GoRoute(
              path: '/teacher',
              builder: (context, state) => const TeacherDashboard(),
            ),
            GoRoute(
              path: '/teacher/courses',
              builder: (context, state) => const TeacherCoursesScreen(),
            ),
            GoRoute(
              path: '/teacher/assignments',
              builder: (context, state) => const TeacherAssignmentsScreen(),
            ),
            GoRoute(
              path: '/teacher/students',
              builder: (context, state) => const TeacherStudentsScreen(),
            ),
            GoRoute(
              path: '/teacher/notifications',
              builder: (context, state) => const NotificationsScreen(),
            ),
          ],
        ),

        // Teacher non-shell routes
        GoRoute(
          path: '/teacher/assignments/create',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const CreateAssignmentScreen(),
        ),
        GoRoute(
          path: '/teacher/assignments/:id',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => AssignmentDetailScreen(
            assignmentId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/teacher/analytics',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const TeacherAnalyticsScreen(),
        ),
        GoRoute(
          path: '/teacher/grades',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const TeacherGradesScreen(),
        ),

        // Student Shell
        ShellRoute(
          navigatorKey: _studentShellKey,
          builder: (context, state, child) => StudentShell(child: child),
          routes: [
            GoRoute(
              path: '/student',
              builder: (context, state) => const StudentDashboard(),
            ),
            GoRoute(
              path: '/student/courses',
              builder: (context, state) => const StudentCoursesScreen(),
            ),
            GoRoute(
              path: '/student/assignments',
              builder: (context, state) => const StudentAssignmentsScreen(),
            ),
            GoRoute(
              path: '/student/grades',
              builder: (context, state) => const StudentGradesScreen(),
            ),
            GoRoute(
              path: '/student/notifications',
              builder: (context, state) => const NotificationsScreen(),
            ),
          ],
        ),

        // Student non-shell routes
        GoRoute(
          path: '/student/assignments/:id',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => StudentAssignmentDetailScreen(
            assignmentId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/student/analytics',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const StudentAnalyticsScreen(),
        ),

        // Shared routes
        GoRoute(
          path: '/chat',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const ChatListScreen(),
        ),
        GoRoute(
          path: '/chat/:chatId',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => ChatScreen(
            otherUserId: state.pathParameters['chatId']!,
          ),
        ),
        GoRoute(
          path: '/profile',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/settings',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    );
  }
}

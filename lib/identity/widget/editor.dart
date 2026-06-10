import 'dart:io';

import 'package:drift/isolate.dart';
import 'package:drift/native.dart';
import 'package:kilt/app/app.dart';
import 'package:kilt/client/client.dart';
import 'package:kilt/identity/identity.dart';
import 'package:kilt/shared/shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> showIdentityEditorDialog({
  required BuildContext context,
  Identity? identity,
  VoidCallback? onDone,
  bool allowHttpHosts = false,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => _IdentityEditorDialog(
      identity: identity,
      onDone: onDone,
      allowHttpHosts: allowHttpHosts,
    ),
  );
}

class _IdentityEditorDialog extends StatefulWidget {
  const _IdentityEditorDialog({
    required this.identity,
    this.onDone,
    this.allowHttpHosts = false,
  });

  final Identity? identity;
  final VoidCallback? onDone;
  final bool allowHttpHosts;

  @override
  State<_IdentityEditorDialog> createState() => _IdentityEditorDialogState();
}

class _IdentityEditorDialogState extends State<_IdentityEditorDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController hostController = TextEditingController(
    text: widget.identity?.host,
  );
  late final TextEditingController usernameController = TextEditingController(
    text: widget.identity?.username,
  );
  late final TextEditingController apikeyController = TextEditingController(
    text: widget.identity?.headers?[HttpHeaders.authorizationHeader] != null
        ? OmittedPasswordTextInputFormatter.passwordOmitted
        : null,
  );
  late bool withAuth = widget.identity?.username != null;
  String? error;

  late final Listenable allFields = Listenable.merge([
    hostController,
    usernameController,
    apikeyController,
  ]);

  @override
  void initState() {
    super.initState();
    allFields.addListener(_clearError);
  }

  void _clearError() {
    if (!mounted) return;
    if (error != null) setState(() => error = null);
  }

  @override
  void dispose() {
    allFields.removeListener(_clearError);
    hostController.dispose();
    usernameController.dispose();
    apikeyController.dispose();
    super.dispose();
  }

  Future<void> _saveAndTest() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => LoginLoadingDialog(
        identity: widget.identity,
        host: hostController.text,
        username: withAuth ? usernameController.text : null,
        apikey: withAuth ? apikeyController.text : null,
        onError: (value) {
          setState(() {
            value ??= 'Check your network connection and login details';
            error = 'Failed to login.\n$value';
          });
          form.validate();
        },
        onDone: () {
          Navigator.of(context).maybePop();
          widget.onDone?.call();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final apiKeysUrl = context.watch<ClientFactory>().apiKeysUrl(
      hostController.text,
      usernameController.text,
    );
    final registrationUrl = context.watch<ClientFactory>().registrationUrl(
      hostController.text,
    );
    final isEditing = widget.identity != null;

    return KeyboardDismisser(
      child: Form(
        key: _formKey,
        child: Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEditing ? 'Edit account' : 'Add account',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  HostFormField(
                    controller: hostController,
                    readOnly: isEditing,
                    allowHttp: widget.allowHttpHosts,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: CheckboxFormField(
                      label: 'Authentication',
                      title: withAuth
                          ? const Text('Login')
                          : const Text('Anonymous'),
                      value: withAuth,
                      onChanged: (value) => setState(() => withAuth = value!),
                    ),
                  ),
                  AnimatedSize(
                    duration: defaultAnimationDuration,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (withAuth) ...[
                          UsernameFormField(controller: usernameController),
                          ApikeyFormField(
                            controller: apikeyController,
                            canOmit: isEditing,
                          ),
                          Row(
                            children: [
                              CrossFade(
                                showChild: apiKeysUrl != null,
                                secondChild: CrossFade(
                                  showChild: registrationUrl != null,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    child: TextButton(
                                      onPressed: () =>
                                          launch(registrationUrl ?? ''),
                                      child: const Text(
                                        'Don\'t have an account? Sign up here',
                                      ),
                                    ),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  child: TextButton(
                                    onPressed: () => launch(apiKeysUrl ?? ''),
                                    child: const Text(
                                      'Where do I find my API key?',
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 10),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              error!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: _saveAndTest,
                        icon: const Icon(Icons.check),
                        label: Text(isEditing ? 'Save' : 'Add'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LoginLoadingDialog extends StatefulWidget {
  const LoginLoadingDialog({
    super.key,
    required this.identity,
    required this.host,
    required this.username,
    required this.apikey,
    this.onError,
    this.onDone,
  });

  final Identity? identity;
  final String host;
  final String? username;
  final String? apikey;
  final ValueSetter<String?>? onError;
  final VoidCallback? onDone;

  @override
  State<LoginLoadingDialog> createState() => _LoginLoadingDialogState();
}

class _LoginLoadingDialogState extends State<LoginLoadingDialog> {
  @override
  void initState() {
    super.initState();
    login();
  }

  Future<void> login() async {
    final navigator = Navigator.of(context);
    final client = context.read<IdentityClient>();
    final identity = widget.identity;
    final host = widget.host;
    final username = widget.username;
    String? apikey = widget.apikey;
    final headers = Map<String, String>.of(identity?.headers ?? {});

    if (username != null && apikey != null) {
      if (apikey == OmittedPasswordTextInputFormatter.passwordOmitted) {
        apikey = parseBasicAuth(headers[HttpHeaders.authorizationHeader])?.$2;
        if (apikey == null) {
          throw StateError(
            'Login failed: API key was omitted but could not be recovered',
          );
        }
      }
      headers[HttpHeaders.authorizationHeader] = encodeBasicAuth(
        username,
        apikey,
      );
    } else {
      headers.remove(HttpHeaders.authorizationHeader);
    }

    try {
      if (identity != null) {
        await client.replace(
          identity.copyWith(host: host, username: username, headers: headers),
        );
      } else {
        await client.add(
          IdentityRequest(host: host, username: username, headers: headers),
        );
      }
    } on DriftRemoteException catch (e) {
      Object remoteError = e.remoteCause;
      String? reason;
      if (remoteError is SqliteException &&
          remoteError.extendedResultCode == 2067) {
        reason = 'You already have an identity under this host and username.';
      }
      await navigator.maybePop();
      widget.onError?.call(reason);
      return;
    }

    await navigator.maybePop();
    widget.onDone?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(4),
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Connecting to ${linkToDisplay(widget.host)} as ${widget.username ?? 'anonymous'}...',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HostFormField extends StatefulWidget {
  const HostFormField({
    super.key,
    required this.controller,
    this.readOnly = false,
    this.allowHttp = false,
  });

  final TextEditingController controller;
  final bool readOnly;
  final bool allowHttp;

  @override
  State<HostFormField> createState() => _HostFormFieldState();
}

class _HostFormFieldState extends State<HostFormField> {
  late final TextEditingController controller = TextEditingController(
    text: widget.controller.text,
  );
  late bool isHttps;

  static const String _http = 'http://';
  static const String _https = 'https://';

  @override
  void initState() {
    super.initState();
    final text = controller.text;
    if (text.startsWith(_http)) {
      isHttps = false;
    } else if (text.startsWith(_https)) {
      isHttps = true;
    } else {
      isHttps = !widget.allowHttp;
    }
    controller.addListener(_updateController);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateController();
    });
  }

  void _updateController() {
    if (controller.text.startsWith(_http)) {
      setState(() => isHttps = false);
      controller.text = controller.text.replaceFirst(_http, '');
    } else if (controller.text.startsWith(_https)) {
      setState(() => isHttps = true);
      controller.text = controller.text.replaceFirst(_https, '');
    }
    widget.controller.text = '${isHttps ? _https : _http}${controller.text}';
  }

  @override
  void dispose() {
    controller.removeListener(_updateController);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = isHttps ? _https : _http;
    final hostField = TextFormField(
      controller: controller,
      readOnly: widget.readOnly,
      decoration: InputDecoration(
        labelText: 'Host',
        border: const OutlineInputBorder(),
        prefixText: widget.allowHttp ? null : scheme,
      ),
      inputFormatters: [FilteringTextInputFormatter.deny(' ')],
      autofillHints: const [AutofillHints.url],
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value!.trim().isEmpty) {
          return 'You must provide a host URL.';
        }
        try {
          Uri.parse('${isHttps ? _https : _http}$value');
        } on FormatException {
          return 'Invalid host URL';
        }
        return null;
      },
    );
    if (!widget.allowHttp) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: hostField,
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: DropdownButtonFormField<bool>(
              initialValue: isHttps,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              items: const [
                DropdownMenuItem(value: true, child: Text('https')),
                DropdownMenuItem(value: false, child: Text('http')),
              ],
              onChanged: widget.readOnly
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() => isHttps = value);
                        _updateController();
                      }
                    },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: hostField),
        ],
      ),
    );
  }
}

class UsernameFormField extends StatelessWidget {
  const UsernameFormField({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: TextFormField(
        controller: controller,
        autocorrect: false,
        decoration: const InputDecoration(
          labelText: 'Username',
          border: OutlineInputBorder(),
        ),
        inputFormatters: [FilteringTextInputFormatter.deny(' ')],
        autofillHints: const [AutofillHints.username],
        textInputAction: TextInputAction.next,
        validator: (value) {
          if (value!.trim().isEmpty) {
            return 'You must provide a username.';
          }
          return null;
        },
      ),
    );
  }
}

class ApikeyFormField extends StatefulWidget {
  const ApikeyFormField({
    super.key,
    required this.controller,
    this.canOmit = false,
  });

  final TextEditingController controller;
  final bool canOmit;

  @override
  State<ApikeyFormField> createState() => _ApikeyFormFieldState();
}

class _ApikeyFormFieldState extends State<ApikeyFormField> {
  static const String _apiKeyExample = '1ca1d165e973d7f8d35b7deb7a2ae54c';
  bool obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: TextFormField(
        autocorrect: false,
        controller: widget.controller,
        decoration: InputDecoration(
          labelText: 'API key',
          helperText: 'e.g. $_apiKeyExample',
          border: const OutlineInputBorder(),
          suffixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: obscurePassword ? 'Show' : 'Hide',
                  icon: Icon(
                    obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() => obscurePassword = !obscurePassword);
                  },
                ),
              ],
            ),
          ),
        ),
        obscureText: obscurePassword,
        inputFormatters: [
          FilteringTextInputFormatter.deny(' '),
          if (widget.canOmit) OmittedPasswordTextInputFormatter(),
        ],
        autofillHints: const [AutofillHints.password],
        textInputAction: TextInputAction.done,
        validator: (value) {
          if (value!.isEmpty) {
            return 'You must provide an API key.\n'
                'e.g. $_apiKeyExample';
          }
          if (widget.canOmit &&
              value == OmittedPasswordTextInputFormatter.passwordOmitted) {
            return null;
          }
          if (!RegExp(r'^[A-Za-z0-9_]{16,80}$').hasMatch(value)) {
            return 'API key is 16–80 characters (letters, digits, optional underscore)\n'
                'e.g. $_apiKeyExample';
          }
          return null;
        },
      ),
    );
  }
}

class OmittedPasswordTextInputFormatter extends TextInputFormatter {
  static final String passwordOmitted = '-' * 24;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (oldValue.text == passwordOmitted) {
      if (newValue.text.contains(passwordOmitted)) {
        newValue = newValue.copyWith(
          text: newValue.text.replaceAll(passwordOmitted, ''),
        );
      } else {
        newValue = newValue.copyWith(text: '');
      }
      newValue = newValue.copyWith(
        selection: TextSelection.collapsed(offset: newValue.text.length),
      );
    }
    return newValue;
  }
}

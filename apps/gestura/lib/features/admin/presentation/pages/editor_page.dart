import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gestura/app/router/app_routes.dart';
import 'package:gestura/di/injection.dart';
import 'package:gestura/features/admin/data/content_store.dart';
import 'package:gestura/features/admin/domain/content_doc.dart';
import 'package:gestura/features/admin/domain/content_kind.dart';
import 'package:gestura/features/admin/presentation/view_models/editor_cubit.dart';
import 'package:gestura/features/admin/presentation/widgets/content_labels.dart';
import 'package:gestura/l10n/l10n.dart';
import 'package:gestura_ui/gestura_ui.dart';
import 'package:go_router/go_router.dart';

class EditorPage extends StatelessWidget {
  const new({required this.kind, super.key, this.id});

  final ContentKind kind;
  final String? id;

  @override
  Widget build(BuildContext context) {
    final existing = id;
    if (existing == null) {
      return BlocProvider(
        create: (_) => EditorCubit(getIt<ContentStore>(), kind),
        child: _EditorView(kind: kind),
      );
    }
    return FutureBuilder<ContentDoc?>(
      future: getIt<ContentStore>().read(kind, existing),
      builder: (context, snapshot) => switch (snapshot) {
        AsyncSnapshot(hasError: true) => Scaffold(
          appBar: AppBar(),
          body: GErrorView(
            title: context.l10n.adminLoadFailed,
            message: context.l10n.failureNetwork,
          ),
        ),
        AsyncSnapshot(connectionState: ConnectionState.done, :final data) =>
          BlocProvider(
            create: (_) => EditorCubit(
              getIt<ContentStore>(),
              kind,
              existing: data ?? ContentDoc(existing, const {}),
            ),
            child: _EditorView(kind: kind),
          ),
        _ => Scaffold(
          appBar: AppBar(),
          body: const Center(child: CircularProgressIndicator()),
        ),
      },
    );
  }
}

class _EditorView extends StatelessWidget {
  const new({required this.kind});

  final ContentKind kind;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sizes = context.gSizes;
    final padding = context.windowSizeClass.screenPadding;
    final cubit = context.read<EditorCubit>();

    return BlocConsumer<EditorCubit, EditorState>(
      listenWhen: (before, after) => before.status != after.status,
      listener: (context, state) {
        final messenger = ScaffoldMessenger.of(context);
        switch (state.status) {
          case EditorStatus.saved:
            messenger.showSnackBar(SnackBar(content: Text(l10n.adminSaved)));
            if (context.canPop()) {
              context.pop();
            } else {
              AdminCollectionRoute(kind: kind.collection).go(context);
            }
          case EditorStatus.failed:
            messenger.showSnackBar(
              SnackBar(content: Text(l10n.adminSaveFailed)),
            );
          case EditorStatus.editing || EditorStatus.saving:
            break;
        }
      },
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          title: Text(
            cubit.isNew
                ? '${l10n.adminAdd} · ${l10n.kindLabel(kind)}'
                : '${l10n.adminEdit} · ${state.id}',
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: EdgeInsetsDirectional.all(padding),
            child: GButton(
              label: l10n.adminSave,
              icon: Icons.check_rounded,
              expand: true,
              isLoading: state.status == EditorStatus.saving,
              onPressed: state.status == EditorStatus.saving
                  ? null
                  : cubit.save,
            ),
          ),
        ),
        body: ListView(
          padding: EdgeInsetsDirectional.fromSTEB(
            padding,
            sizes.xs,
            padding,
            sizes.xl,
          ),
          children: [
            TextFormField(
              initialValue: state.id,
              enabled: cubit.isNew,
              onChanged: cubit.setId,
              decoration: InputDecoration(
                labelText: l10n.adminFieldId,
                errorText: switch (state.idError) {
                  IdError.format => l10n.adminErrorIdFormat,
                  IdError.taken => l10n.adminErrorIdTaken,
                  null => null,
                },
              ),
            ),
            SizedBox(height: sizes.sm),
            SwitchListTile(
              value: state.values['published'] == true,
              onChanged: (value) => cubit.setPublished(published: value),
              title: Text(l10n.adminFieldPublished),
              subtitle: Text(
                state.values['published'] == true
                    ? l10n.adminPublished
                    : l10n.adminDraft,
              ),
            ),
            for (final field in kind.fields) ...[
              SizedBox(height: sizes.sm),
              FieldEditor(
                spec: field,
                value: state.values[field.name.name],
                error: state.errors[field.name],
                onChanged: (value) => cubit.setValue(field.name, value),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class FieldEditor extends StatelessWidget {
  const new({
    required this.spec,
    required this.value,
    required this.onChanged,
    super.key,
    this.error,
  });

  final FieldSpec spec;
  final Object? value;
  final FieldError? error;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final label = l10n.fieldLabel(spec.name);
    final errorText = switch (error) {
      final FieldError error => l10n.errorLabel(error),
      null => null,
    };
    final decoration = InputDecoration(labelText: label, errorText: errorText);

    return switch (spec.type) {
      FieldType.text || FieldType.mediaPath => TextFormField(
        initialValue: value as String? ?? '',
        onChanged: onChanged,
        maxLength: spec.type == FieldType.text ? spec.max : null,
        decoration: decoration,
      ),
      FieldType.number => TextFormField(
        initialValue: value as String? ?? '',
        onChanged: onChanged,
        keyboardType: TextInputType.number,
        decoration: decoration,
      ),
      FieldType.toggle => SwitchListTile(
        value: value == true,
        onChanged: onChanged,
        title: Text(label),
      ),
      FieldType.choice => DropdownButtonFormField<String>(
        initialValue: spec.choices.contains(value) ? value as String? : null,
        items: [
          for (final choice in spec.choices)
            DropdownMenuItem(value: choice, child: Text(choice)),
        ],
        onChanged: onChanged,
        decoration: decoration,
      ),
      FieldType.reference => StreamBuilder<List<ContentDoc>>(
        stream: getIt<ContentStore>().watch(spec.reference!),
        builder: (context, snapshot) {
          final ids = [
            for (final doc in snapshot.data ?? const <ContentDoc>[]) doc.id,
          ]..sort();
          final current = value as String?;
          return DropdownButtonFormField<String>(
            initialValue: current,
            items: [
              for (final id in {...ids, ?current})
                DropdownMenuItem(value: id, child: Text(id)),
            ],
            onChanged: onChanged,
            decoration: decoration,
          );
        },
      ),
      FieldType.localized => _LocalizedEditor(
        label: label,
        errorText: errorText,
        value: (value as Map<String, String>?) ?? const {},
        onChanged: onChanged,
      ),
      FieldType.jsonList => TextFormField(
        initialValue: value == null
            ? ''
            : const JsonEncoder.withIndent('  ').convert(value),
        onChanged: (text) => onChanged(parseJsonList(text)),
        minLines: 4,
        maxLines: 14,
        style: const TextStyle(fontFamily: 'monospace'),
        decoration: decoration,
      ),
    };
  }
}

class _LocalizedEditor extends StatelessWidget {
  const new({
    required this.label,
    required this.value,
    required this.onChanged,
    this.errorText,
  });

  final String label;
  final String? errorText;
  final Map<String, String> value;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sizes = context.gSizes;
    final theme = Theme.of(context);

    return GCard(
      tone: GCardTone.low,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: theme.textTheme.titleSmall),
          if (errorText case final String text)
            Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          for (final code in contentLanguages) ...[
            SizedBox(height: sizes.xs),
            TextFormField(
              initialValue: value[code] ?? '',
              textDirection: code == 'ar' ? TextDirection.rtl : null,
              onChanged: (text) => onChanged({...value, code: text}),
              decoration: InputDecoration(labelText: l10n.languageLabel(code)),
            ),
          ],
        ],
      ),
    );
  }
}

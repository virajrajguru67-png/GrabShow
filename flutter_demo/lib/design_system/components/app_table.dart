import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/design_tokens.dart';

class AppTableColumn {
  const AppTableColumn({
    required this.label,
    this.width,
    this.alignment = Alignment.centerLeft,
  });

  final String label;
  final double? width;
  final Alignment alignment;
}

class AppTableRow {
  const AppTableRow({
    required this.cells,
    this.onTap,
  });

  final List<Widget> cells;
  final VoidCallback? onTap;
}

class AppTable extends StatelessWidget {
  const AppTable({
    required this.columns,
    required this.rows,
    this.headerBuilder,
    this.emptyBuilder,
    this.minWidth = 600,
    this.rowHeight = 60,
    this.headerHeight = 52,
    this.horizontalPadding = DSSpacing.lg,
    super.key,
  });

  final List<AppTableColumn> columns;
  final List<AppTableRow> rows;
  final WidgetBuilder? headerBuilder;
  final WidgetBuilder? emptyBuilder;
  final double minWidth;
  final double rowHeight;
  final double headerHeight;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final table = DataTable(
      showCheckboxColumn: false,
      headingRowHeight: headerHeight,
      dataRowMinHeight: rowHeight,
      dataRowMaxHeight: rowHeight,
      dividerThickness: 0.6,
      border: TableBorder(
        horizontalInside: BorderSide(
          color: AppColors.border.withValues(alpha: 0.5),
          width: 0.6,
        ),
      ),
      headingTextStyle: Theme.of(context)
          .textTheme
          .labelMedium
          ?.copyWith(color: AppColors.textMuted),
      dataTextStyle: Theme.of(context).textTheme.bodyMedium,
      columns: [
        for (final column in columns)
          DataColumn(
            label: Align(
              alignment: column.alignment,
              child: Text(column.label),
            ),
          ),
      ],
      rows: [
        if (rows.isEmpty)
          DataRow(
            cells: [
              DataCell(
                Container(
                  height: rowHeight,
                  alignment: Alignment.centerLeft,
                  child: emptyBuilder != null
                      ? emptyBuilder!(context)
                      : Text(
                          'No data available',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppColors.textMuted),
                        ),
                ),
              ),
              for (int i = 1; i < columns.length; i++)
                const DataCell(SizedBox.shrink()),
            ],
          )
        else
          for (final row in rows)
            DataRow(
              cells: [
                for (int index = 0; index < columns.length; index++)
                  DataCell(
                    Align(
                      alignment: columns[index].alignment,
                      child: row.cells[index],
                    ),
                    onTap: row.onTap,
                  ),
              ],
            ),
      ],
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(DSRadii.lg),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: minWidth),
          child: table,
        ),
      ),
    );
  }
}

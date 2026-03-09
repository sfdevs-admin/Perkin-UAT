/**
 * Created by frankvanloon on 2/1/21.
 */

export { CheckboxGrid };

class CheckboxGrid {

	gridResult;
	gridColumns;
	gridData;
	gridDraftValues;
	gridSelectedRows;

	constructor() {
	}

	loadResultGrid(resultGrid, rowLabel, colWidth) {
		console.log('Grid Result = ' + JSON.stringify(resultGrid));
		this.gridResult = resultGrid;
		this.gridColumns = [{ label: rowLabel, fieldName: 'rowName', editable: false,
        	fixedWidth: 200, hideDefaultActions: true }];
		this.gridResult.columnValues.forEach(c =>
			this.gridColumns.push({label: c.label, fieldName: c.value, type: 'boolean', editable: true,
				fixedWidth: colWidth, hideDefaultActions: true, actions: [ { label: 'Select All', checked: false, name:'all' } ]})
	    );
		this.gridData = this.loadGridData(this.gridResult);
		this.gridDraftValues = [];
		this.gridSelectedRows = [];
		console.log('Loaded GridData = ' + JSON.stringify(this.gridData));
	}

	loadGridData(grid) {
		var result = [];
		var rowNum;
		for (rowNum = 0; rowNum < grid.rowValues.length; rowNum++) {
			var r = grid.rowValues[rowNum];
			var rowData = { rowId: r.value, rowName: r.label };
			grid.columnValues.forEach(c =>
				rowData[c.value] = grid.grid[r.value][c.value]
			);
			result.push(rowData);
		}
		return result;
	}

	handleGridCellChange(event) {
		var changedRows = event.detail.draftValues;
		// [{"a8gK0000000KmafIAC":true,"rowId":"a7iK0000000D7qeIAC"}]
		console.log('Cell Changed=> ' + JSON.stringify(event.detail));
		var rowNum, fieldNum;
		for (rowNum = 0; rowNum < changedRows.length; rowNum++) {
			var rowChange = changedRows[rowNum];
			var draftRow = this.gridDraftValues.find(d => d.rowId === rowChange.rowId);
			if (draftRow) {
				var fields = Object.keys(rowChange);
				fields.forEach(f => draftRow[f] = rowChange[f]);
			} else {
				this.gridDraftValues.push(rowChange);
			}
		}
	}

	handleGridHeaderAction(event) {
		// Retrieves the name of the selected filter
		const actionName = event.detail.action.name;
		if (actionName === 'all') {
			this.selectAllColumn(event);
		}
	}

	selectAllColumn(event) {
		const colDef = event.detail.columnDefinition;
		var column = this.gridColumns.find(c => c.fieldName === colDef.fieldName);
		console.log('Select All Column=' + column.fieldName);
		// Toggle the action checkmark
		var action = column.actions.find(a => a.name === 'all');
		action.checked = !action.checked;
		//console.log('SELECT ALL[' + action.checked + '] ... ');
		var r;
		for (r = 0; r < this.gridResult.rowValues.length; r++) {
			let rowValue = this.gridResult.rowValues[r].value;
			var draftRow = this.gridDraftValues.find(d => d.rowId === rowValue);
			if (draftRow) {
				draftRow[column.fieldName] = action.checked;
			} else {
				draftRow = { rowId: rowValue };
				draftRow[column.fieldName] = action.checked;
				this.gridDraftValues.push(draftRow);
			}
		}
	}

	selectRows(event) {
		//console.log('ROW SELECT = ' + JSON.stringify(event.detail));
		const selRows = event.detail.selectedRows;
		for (const r of selRows) {
			let rowIdx = this.gridSelectedRows.indexOf(r.rowId);
			if (rowIdx >= 0) {
				// Already selected.. do nothing
			} else {
				this.gridSelectedRows.push(r.rowId); // Add row
				this.toggleRow(r.rowId, true);
			}
		}

		const rowsToDelete = [];
		for (const selectedId of this.gridSelectedRows) {
			let rowIdx = selRows.findIndex(sr => selectedId === sr.rowId);
			if (rowIdx < 0) {
				rowsToDelete.push(selectedId);
				this.toggleRow(selectedId, false);
			}
		}

		for (const deleteId of rowsToDelete) {
			let rowIdx = this.gridSelectedRows.indexOf(deleteId);
			this.gridSelectedRows.splice(rowIdx, 1); // Remove row
		}
	}

	toggleRow(rowId, isChecked) {
		let draftRow = this.gridDraftValues.find(d => d.rowId === rowId);
		if (!draftRow) {
			draftRow = { rowId: rowId };
			this.gridDraftValues.push(draftRow);
		}
		this.gridResult.columnValues.forEach(c => draftRow[c.value] = isChecked);
	}

	prepareGridForSave(event) {
		this.isProcessing = true;
		var changedRows = event.detail.draftValues;
		console.log('Saving Grid DraftValues = ' + JSON.stringify(changedRows));
		var grid = {}; // Make a clean object..
		var rowNum, fieldNum;
		for (rowNum = 0; rowNum < changedRows.length; rowNum++) {
			var rowData = changedRows[rowNum];
			grid[rowData.rowId] = {};
			var fields = Object.keys(rowData);
			for (fieldNum = 0; fieldNum < fields.length; fieldNum++) {
				var fieldName = fields[fieldNum];
				if (fieldName !== 'rowId' && fieldName !== 'rowName') {
					grid[rowData.rowId][fieldName] = rowData[fieldName];
				}
			}
		}
		this.gridResult = grid;
	}

}
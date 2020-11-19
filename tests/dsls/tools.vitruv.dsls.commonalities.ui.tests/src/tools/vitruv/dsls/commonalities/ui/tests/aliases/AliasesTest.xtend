package tools.vitruv.dsls.commonalities.ui.tests.aliases

import tools.vitruv.dsls.commonalities.testutils.ExecutionTestCompiler
import tools.vitruv.dsls.commonalities.ui.executiontests.IdentifiedExecutionTest

/**
 * Inherits the Identified execution tests, but uses the modified commonalities
 * files located in this package.
 */
class AliasesTest extends IdentifiedExecutionTest {
	override createCompiler(ExecutionTestCompiler.Factory factory) {
		factory.createCompiler [
			projectName = 'commonalities-test-aliases'
			commonalities = #['Identified.commonality', 'Sub.commonality']
			domainDependencies = #[
				'tools.vitruv.testutils.domains',
				'tools.vitruv.testutils.metamodels'
			]
		]
	}
}

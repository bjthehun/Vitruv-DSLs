package tools.vitruv.dsls.commonalities.testutils

import com.google.inject.Inject
import edu.kit.ipd.sdq.commons.util.org.eclipse.core.resources.IProjectUtil
import java.io.ByteArrayInputStream
import java.io.File
import java.net.URLClassLoader
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.Paths
import java.util.ArrayList
import java.util.HashSet
import java.util.Hashtable
import java.util.function.Consumer
import org.apache.log4j.Logger
import org.eclipse.core.resources.IFolder
import org.eclipse.core.resources.IProject
import org.eclipse.core.resources.IResource
import org.eclipse.core.resources.IncrementalProjectBuilder
import org.eclipse.core.runtime.NullProgressMonitor
import org.eclipse.core.runtime.Platform
import org.eclipse.jdt.core.JavaCore
import org.eclipse.osgi.internal.framework.EquinoxBundle
import org.eclipse.osgi.storage.BundleInfo.Generation
import org.eclipse.pde.core.target.ITargetLocation
import org.eclipse.pde.core.target.LoadTargetDefinitionJob
import org.eclipse.pde.internal.core.PDECore
import org.eclipse.pde.internal.core.natures.PDE
import org.eclipse.pde.internal.core.target.TargetPlatformService
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import org.eclipse.xtext.ui.XtextProjectHelper
import org.eclipse.xtext.ui.util.JREContainerProvider
import tools.vitruv.dsls.common.VitruviusDslsCommonConstants
import tools.vitruv.dsls.commonalities.generator.CommonalitiesGenerationSettings
import tools.vitruv.framework.change.processing.ChangePropagationSpecification

import static com.google.common.base.Preconditions.*
import static java.util.stream.Collectors.toList
import static org.eclipse.core.resources.ResourcesPlugin.getWorkspace
import static tools.vitruv.testutils.TestLauncher.currentTestLauncher

import static extension edu.kit.ipd.sdq.commons.util.java.lang.IterableUtil.*

@FinalFieldsConstructor
final class ExecutionTestCompiler {
	static val Logger logger = Logger.getLogger(ExecutionTestCompiler)

	static val String COMPLIANCE_LEVEL = '1.8';
	static val TEST_PROJECT_GENERATED_SOURCES_FOLDER_NAME = 'src-gen'
	static val TEST_PROJECT_SOURCES_FOLDER_NAME = 'src'
	static val TEST_PROJECT_COMPILATION_FOLDER = 'bin'

	var Iterable<Class<? extends ChangePropagationSpecification>> loadedChangePropagationClasses
	var compiled = false
	val Class<?> commonalitiesOwningClass
	val Path compilationProjectDir
	val CommonalitiesGenerationSettings generationSettings
	val Iterable<String> commonalityFilePaths
	val Iterable<String> domainDependencies

	def getChangePropagationSpecifications() {
		if (!compiled) {
			val compiledFolder = compile()
			compiled = true

			val classLoader = new URLClassLoader(#[compiledFolder.toUri.toURL], commonalitiesOwningClass.classLoader)
			loadedChangePropagationClasses = Files.find(compiledFolder, Integer.MAX_VALUE, [ path, info |
				val fileName = path.fileName.toString
				fileName.contains('ChangePropagationSpecification') && fileName.endsWith('.class')
			]).map[compiledFolder.relativize(it)].map[toString.replace('.class', '').replace(File.separator, '.')].map [
				classLoader.loadClass(it) as Class<? extends ChangePropagationSpecification>
			].collect(toList)
		}

		checkState(loadedChangePropagationClasses.size > 0, "Failed to load change propagations!")

		return loadedChangePropagationClasses.mapFixed[declaredConstructor.newInstance].groupBy [
			new Pair(it.sourceDomain, it.targetDomain)
		].entrySet.mapFixed [
			val sourceDomain = it.key.key;
			val targetDomain = it.key.value;
			new CombinedChangePropagationSpecification(sourceDomain, targetDomain, it.value)
		]
	}

	private def compile() {
		val testProject = prepareTestProject()
		setGenerationSettings()

		// Disable automatic building
		workspace.description = workspace.description => [autoBuilding = false]

		// copy in the source files
		for (commonalityFile : commonalityFilePaths) {
			val commonalityFileInputStream = commonalitiesOwningClass.getResourceAsStream(commonalityFile)
			if (commonalityFileInputStream === null) {
				throw new RuntimeException("Could not find commonality file at: " + commonalityFile)
			}
			testProject.sourceFolder.getFile(Paths.get(commonalityFile).fileName.toString).create(
				commonalityFileInputStream, true, null)
		}

		testProject.refresh()
		// build the files.
		// The build order is different from what Eclipse would do by
		// default. The order is important to get a build without errors.
		testProject.build(PDE.MANIFEST_BUILDER_ID)
		testProject.build(PDE.SCHEMA_BUILDER_ID)

		logger.trace("Xtext Build")
		testProject.build(XtextProjectHelper.BUILDER_ID)
		testProject.refresh()

		logger.trace("Java Build")
		testProject.build(JavaCore.BUILDER_ID)

		return testProject.binFolder.path
	}

	/**
	 * Sets up the test project. Applies all settings needed to make the
	 * project usable. Some of those settings are not required for the tests to
	 * work, but make it possible to look around and debug in the generated
	 * project.
	 */
	private def prepareTestProject() {
		setTargetPlatform()

		val projectName = '''«commonalitiesOwningClass.simpleName»-Commonalities'''
		val eclipseProject = IProjectUtil.createProjectAt(projectName, compilationProjectDir) => [
			open(null)
			setDescription(description => [
				natureIds = #[JavaCore.NATURE_ID, XtextProjectHelper.NATURE_ID, PDE.PLUGIN_NATURE]
			], null)
			createManifestMf()
		]
		val sourcesFolder = eclipseProject.createFolder(TEST_PROJECT_SOURCES_FOLDER_NAME)
		val generatedSourcesFolder = eclipseProject.createFolder(TEST_PROJECT_GENERATED_SOURCES_FOLDER_NAME)
		val generatedSourcesSourceFolder = JavaCore.newSourceEntry(generatedSourcesFolder.fullPath)
		val sourcesSourceFolder = JavaCore.newSourceEntry(sourcesFolder.fullPath)
		val requiredPluginsContainer = JavaCore.newContainerEntry(PDECore.REQUIRED_PLUGINS_CONTAINER_PATH)
		val jreContainer = JREContainerProvider.defaultJREContainerEntry
		val javaProjectBinFolder = eclipseProject.getFolder(TEST_PROJECT_COMPILATION_FOLDER)
		val projectClasspath = #[sourcesSourceFolder, generatedSourcesSourceFolder, jreContainer,
			requiredPluginsContainer]
		JavaCore.create(eclipseProject) => [
			options = new Hashtable => [
				put(JavaCore.COMPILER_CODEGEN_TARGET_PLATFORM, COMPLIANCE_LEVEL)
				put(JavaCore.COMPILER_COMPLIANCE, COMPLIANCE_LEVEL)
				put(JavaCore.COMPILER_SOURCE, COMPLIANCE_LEVEL)
			]
			setRawClasspath(projectClasspath, javaProjectBinFolder.fullPath, true, null)
			save(null, true)
		]

		return new Project(eclipseProject, sourcesFolder, javaProjectBinFolder)
	}

	private def setGenerationSettings() {
		switch (currentTestLauncher) {
			case ECLIPSE:
				// always generate reactions when run from Eclipse, as they are helpful for debugging.
				generationSettings.createReactionFiles = true
			case SUREFIRE:
				// never create reactions when run from Maven because it is unnecessary and logs errors.
				generationSettings.createReactionFiles = false
			case UNKNOWN: {
			} // use default 
		}
	}

	private def createManifestMf(IProject project) {
		val relevantMirbaseDependencies = VitruviusDslsCommonConstants.VITRUVIUS_DEPENDENCIES.filter [
			!contains('mapping')
		]
		val mf = '''
			Manifest-Version: 1.0
			Bundle-ManifestVersion: 2
			Bundle-Name: Commonalities Language Test Project
			Bundle-Vendor: Vitruv-Tools
			Bundle-Version: 1.0.0.qualifier
			Bundle-SymbolicName: «project.name»; singleton:=true
			Bundle-ActivationPolicy: lazy
			Require-Bundle: tools.vitruv.extensions.dslsruntime.commonalities,
			  tools.vitruv.framework.metamodel,
			  tools.vitruv.extensions.emf,
			  org.eclipse.xtext.xbase.lib,
			  «FOR domainDependency : domainDependencies»
			  	«domainDependency»,
			  «ENDFOR»
			  «FOR mirbaseDependency : relevantMirbaseDependencies SEPARATOR ','»
			  	«mirbaseDependency»
			  «ENDFOR»
			Bundle-RequiredExecutionEnvironment: JavaSE-«COMPLIANCE_LEVEL»
		'''
		(project.getFolder('META-INF') => [create(true, false, null)]).getFile('MANIFEST.MF').create(
			new ByteArrayInputStream(mf.bytes), true, null)
	}

	@FinalFieldsConstructor
	private static class Project {
		val IProject eclipseProject
		val IFolder sourceFolder
		val IFolder binFolder

		private def build(String configName) {
			eclipseProject.setDescription(eclipseProject.description => [
				buildSpec = #[newCommand => [builderName = configName]]
			], null)
			eclipseProject.build(IncrementalProjectBuilder.FULL_BUILD, new NullProgressMonitor)
		}

		private def refresh() {
			eclipseProject.refreshLocal(IResource.DEPTH_INFINITE, new NullProgressMonitor)
		}
	}

	/**
	 * Sets a target platform in the test platform. This is required to run the
	 * tests with tycho.
	 * 
	 * Taken from http://git.eclipse.org/c/gmf-tooling/org.eclipse.gmf-tooling.git/tree/tests/org.eclipse.gmf.tests/src/org/eclipse/gmf/tests/Utils.java#n146
	 * 
	 * Necessary because of this bug: https://bugs.eclipse.org/bugs/show_bug.cgi?id=343156
	 */
	@SuppressWarnings('restriction')
	static def void setTargetPlatform() {
		val tpService = TargetPlatformService.getDefault()
		val bundles = Platform.getBundle('org.eclipse.core.runtime').getBundleContext().getBundles()
		val bundleContainers = new ArrayList<ITargetLocation>()
		val dirs = new HashSet<File>()

		for (bundle : bundles) {
			val bundleImpl = bundle as EquinoxBundle
			val generation = bundleImpl.getModule().getCurrentRevision().getRevisionInfo() as Generation
			val file = generation.getBundleFile().getBaseFile()
			val folder = file.getParentFile()
			if (!dirs.contains(folder)) {
				dirs.add(folder)
				bundleContainers.add(tpService.newDirectoryLocation(folder.getAbsolutePath()))
			}
		}
		val targetDef = tpService.newTarget() => [
			name = 'Test Target Platform'
			targetLocations = bundleContainers
			arch = Platform.OSArch
			OS = Platform.OS
			WS = Platform.WS
			NL = Platform.NL
		]
		tpService.saveTargetDefinition(targetDef)

		val job = new LoadTargetDefinitionJob(targetDef)
		job.schedule()
		job.join()
	}

	private def createFolder(IProject project, String name) {
		project.getFolder(name) => [
			create(true, false, null)
		]
	}

	private static def getPath(IResource eclipseResource) {
		eclipseResource.rawLocation.toFile.toPath
	}

	@Accessors
	static class Parameters {
		var Object commonalitiesOwner
		var Path compilationProjectDir
		var Iterable<String> commonalities = null
		var Iterable<String> domainDependencies = null
	}

	static class Factory {
		@Inject CommonalitiesGenerationSettings generationSettings
		var parameters = new Parameters

		def setParameters(Consumer<ExecutionTestCompiler.Parameters> configurer) {
			configurer.accept(parameters)
		}

		def createCompiler(Consumer<ExecutionTestCompiler.Parameters> configurer) {
			setParameters(configurer)
			return new ExecutionTestCompiler(
				parameters.commonalitiesOwner.class,
				parameters.compilationProjectDir,
				generationSettings,
				parameters.commonalities,
				parameters.domainDependencies
			)
		}
	}
}

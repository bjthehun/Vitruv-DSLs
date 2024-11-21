/*
 * generated by Xtext 2.9.0
 */
package tools.vitruv.dsls.reactions.jvmmodel

import com.google.inject.Inject
import org.eclipse.xtext.xbase.jvmmodel.AbstractModelInferrer
import org.eclipse.xtext.xbase.jvmmodel.IJvmDeclaredTypeAcceptor
import tools.vitruv.dsls.reactions.codegen.classgenerators.RoutineFacadeClassGenerator
import tools.vitruv.dsls.reactions.codegen.classgenerators.RoutineClassGenerator
import tools.vitruv.dsls.reactions.language.toplevelelements.Routine
import tools.vitruv.dsls.reactions.language.toplevelelements.Reaction
import tools.vitruv.dsls.reactions.language.toplevelelements.ReactionsFile
import tools.vitruv.dsls.reactions.language.toplevelelements.ReactionsSegment
import tools.vitruv.dsls.reactions.codegen.typesbuilder.JvmTypesBuilderWithoutAssociations
import tools.vitruv.dsls.reactions.codegen.typesbuilder.TypesBuilderExtensionProvider
import tools.vitruv.dsls.reactions.codegen.classgenerators.ReactionClassGenerator
import tools.vitruv.dsls.reactions.codegen.classgenerators.ClassGenerator
import tools.vitruv.dsls.reactions.codegen.classgenerators.ChangePropagationSpecificationClassGenerator
import tools.vitruv.dsls.reactions.codegen.classgenerators.OverriddenRoutinesFacadeClassGenerator
import tools.vitruv.dsls.reactions.codegen.classgenerators.RoutinesFacadesProviderClassGenerator
import static extension tools.vitruv.dsls.reactions.codegen.helper.ReactionsImportsHelper.*
import static extension tools.vitruv.dsls.reactions.codegen.helper.ReactionsElementsCompletionChecker.isReferenceable

/**
 * <p>Infers a JVM model for the Xtend code blocks of the reaction file model.</p> 
 *
 * <p>The resulting classes are not to be persisted but only to be used for content assist purposes.</p>
 * 
 * @author Heiko Klare     
 */
class ReactionsLanguageJvmModelInferrer extends AbstractModelInferrer  {

	@Inject extension JvmTypesBuilderWithoutAssociations _typesBuilder
	@Inject TypesBuilderExtensionProvider typesBuilderExtensionProvider;
	
	
	private def void updateBuilders() {
		typesBuilderExtensionProvider.setBuilders(_typesBuilder, _typeReferenceBuilder, _annotationTypesBuilder);
	}
	
	def dispatch void generate(Reaction reaction, IJvmDeclaredTypeAcceptor acceptor, boolean isPreIndexingPhase) {
		acceptor.accept(new ReactionClassGenerator(reaction, typesBuilderExtensionProvider), reaction.reactionsSegment);
	}
	
	def dispatch void generate(Routine routine, IJvmDeclaredTypeAcceptor acceptor, boolean isPreIndexingPhase) {
		acceptor.accept(new RoutineClassGenerator(routine, typesBuilderExtensionProvider), routine.reactionsSegment);
	}
	
	def dispatch void infer(ReactionsFile file, IJvmDeclaredTypeAcceptor acceptor, boolean isPreIndexingPhase) {
		updateBuilders();
		
		for (reactionsSegment : file.reactionsSegments.filter[it.isReferenceable]) {
			acceptor.accept(new RoutineFacadeClassGenerator(reactionsSegment, typesBuilderExtensionProvider), reactionsSegment);
			for (overriddenRoutinesImportPath : reactionsSegment.parsedOverriddenRoutinesImportPaths) {
				acceptor.accept(new OverriddenRoutinesFacadeClassGenerator(reactionsSegment, overriddenRoutinesImportPath, typesBuilderExtensionProvider), reactionsSegment);
			}
			acceptor.accept(new RoutinesFacadesProviderClassGenerator(reactionsSegment, typesBuilderExtensionProvider), reactionsSegment);
			for (effect : reactionsSegment.routines.filter[it.isReferenceable]) {
				generate(effect, acceptor, isPreIndexingPhase);
			}
			for (reaction : reactionsSegment.reactions.filter[it.isReferenceable]) {
				generate(reaction, acceptor, isPreIndexingPhase);
			}
			acceptor.accept(new ChangePropagationSpecificationClassGenerator(reactionsSegment, typesBuilderExtensionProvider), reactionsSegment);
		}

	}
	
	def private static accept(IJvmDeclaredTypeAcceptor acceptor, extension ClassGenerator generator, ReactionsSegment reactionsSegment) {
		acceptor.accept(generator.generateEmptyClass()) [
			// sometimes the jvm model inferrer is called after indexing, but cross-references of reactions imports are not resolvable,
			// we need to skip class-body generation then:
			if (reactionsSegment.allImportsResolvable) {
				generateBody();
			}
		]
	}
}
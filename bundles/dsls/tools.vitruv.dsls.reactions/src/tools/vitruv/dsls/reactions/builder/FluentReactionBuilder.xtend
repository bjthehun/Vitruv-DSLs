package tools.vitruv.dsls.reactions.builder

import java.util.ArrayList
import java.util.function.Consumer
import java.util.function.Function
import org.eclipse.emf.ecore.EAttribute
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EClassifier
import org.eclipse.emf.ecore.EReference
import org.eclipse.xtext.common.types.JvmOperation
import org.eclipse.xtext.common.types.access.IJvmTypeProvider
import org.eclipse.xtext.xbase.XExpression
import org.eclipse.xtext.xbase.XbaseFactory
import tools.vitruv.dsls.mirbase.mirBase.MirBaseFactory
import tools.vitruv.dsls.reactions.builder.FluentRoutineBuilder.RoutineStartBuilder
import tools.vitruv.dsls.reactions.reactionsLanguage.ElementChangeType
import tools.vitruv.dsls.reactions.reactionsLanguage.ModelElementChange
import tools.vitruv.dsls.reactions.reactionsLanguage.Reaction
import tools.vitruv.dsls.reactions.reactionsLanguage.ReactionsLanguageFactory

import static com.google.common.base.Preconditions.*
import static tools.vitruv.dsls.reactions.codegen.helper.ReactionsLanguageConstants.*

class FluentReactionBuilder extends FluentReactionsSegmentChildBuilder {

	var Reaction reaction
	var anonymousRoutineCounter = 0
	var EClassifier valueType
	var EClass affectedElementType

	package new(String reactionName, FluentBuilderContext context) {
		super(context)
		reaction = ReactionsLanguageFactory.eINSTANCE.createReaction => [
			name = reactionName
		]
	}

	def package start() {
		return new TriggerBuilder(this)
	}

	override protected attachmentPreparation() {
		super.attachmentPreparation()
		checkState(reaction.trigger !== null, '''No trigger was set on the «this»!''')
		checkState(reaction.callRoutine !== null, '''No routine call was set on the «this»!''')
	}

	static class TriggerBuilder {
		val extension FluentReactionBuilder builder

		private new(FluentReactionBuilder builder) {
			this.builder = builder
		}

		def afterAnyChange() {
			reaction.trigger = ReactionsLanguageFactory.eINSTANCE.createArbitraryModelChange
			return new PreconditionOrRoutineCallBuilder(builder)
		}

		def afterElement(EClass element) {
			val change = ReactionsLanguageFactory.eINSTANCE.createModelElementChange => [
				elementType = MirBaseFactory.eINSTANCE.createMetaclassReference.reference(element)
			]
			reaction.trigger = change
			return new ChangeTypeBuilder(builder, change, element)
		}
		
		def afterAttributeInsertIn(EAttribute attribute) {
			valueType = attribute.EType
			affectedElementType = attribute.EContainingClass
			reaction.trigger = ReactionsLanguageFactory.eINSTANCE.createModelAttributeInsertedChange => [
				feature = MirBaseFactory.eINSTANCE.createMetaclassEAttributeReference.reference(attribute)
			]
			return new PreconditionOrRoutineCallBuilder(builder)
		}
		
		def afterAttributeReplacedAt(EAttribute attribute) {
			valueType = attribute.EType
			affectedElementType = attribute.EContainingClass
			reaction.trigger = ReactionsLanguageFactory.eINSTANCE.createModelAttributeReplacedChange => [
				feature = MirBaseFactory.eINSTANCE.createMetaclassEAttributeReference.reference(attribute)
			]
			return new PreconditionOrRoutineCallBuilder(builder)
		}
		
		def afterAttributeRemoveFrom(EAttribute attribute) {
			valueType = attribute.EType
			affectedElementType = attribute.EContainingClass
			reaction.trigger = ReactionsLanguageFactory.eINSTANCE.createModelAttributeRemovedChange => [
				feature = MirBaseFactory.eINSTANCE.createMetaclassEAttributeReference.reference(attribute)
			]
			return new PreconditionOrRoutineCallBuilder(builder)
		}
	}

	static class ChangeTypeBuilder {
		val extension FluentReactionBuilder builder
		val ModelElementChange modelElementChange
		val EClass element

		private new(FluentReactionBuilder builder, ModelElementChange modelElementChange, EClass element) {
			this.builder = builder
			this.modelElementChange = modelElementChange
			this.element = element
		}

		def created() {
			affectedElementType = element
			continueWithChangeType(ReactionsLanguageFactory.eINSTANCE.createElementCreationChangeType)
		}

		def deleted() {
			affectedElementType = element
			continueWithChangeType(ReactionsLanguageFactory.eINSTANCE.createElementDeletionChangeType)
		}

		def insertedAsRoot() {
			valueType = element
			continueWithChangeType(ReactionsLanguageFactory.eINSTANCE.createElementInsertionAsRootChangeType)
		}

		def insertedIn(EReference reference) {
			valueType = element
			continueWithChangeType(ReactionsLanguageFactory.eINSTANCE.createElementInsertionInListChangeType => [
				feature = MirBaseFactory.eINSTANCE.createMetaclassEReferenceReference.reference(reference)
			])
		}

		def private continueWithChangeType(ElementChangeType changeType) {
			modelElementChange.changeType = changeType
			return new PreconditionOrRoutineCallBuilder(builder)
		}
	}

	static class RoutineCallBuilder {
		protected val extension FluentReactionBuilder builder

		private new(FluentReactionBuilder builder) {
			this.builder = builder
		}

		def call(FluentRoutineBuilder routineBuilder) {
			checkNotNull(routineBuilder)
			checkState(routineBuilder.
				readyToBeAttached, '''The «routineBuilder» is not sufficiently initialised to be set on the «builder»''')
			checkState((!routineBuilder.requireNewValue && !routineBuilder.requireOldValue) || valueType !==
				null, '''The «routineBuilder» requires a model value type, but the «builder» doesn’t have one!''')
			builder.transferReactionsSegmentTo(routineBuilder)
			reaction.callRoutine = ReactionsLanguageFactory.eINSTANCE.createReactionRoutineCall => [
				code = (XbaseFactory.eINSTANCE.createXFeatureCall => [
					explicitOperationCall = true
				]).whenJvmTypes [
					val routineCallMethod = routineCallMethod
					feature = routineBuilder.jvmOperation
					implicitReceiver = routineCallMethod.argument(
						REACTION_USER_EXECUTION_ROUTINE_CALL_FACADE_PARAMETER_NAME)
					featureCallArguments += routineBuilder.requiredArgumentsFrom(routineCallMethod)
				]
			]
			if (affectedElementType !== null) {
				routineBuilder.affectedElementType = affectedElementType
			}
			if (valueType !== null) {
				routineBuilder.valueType = valueType
			}
			readyToBeAttached = true
			return builder
		}

		def call(String routineName, Consumer<RoutineStartBuilder> routineInitializer) {
			val routineBuilder = new FluentRoutineBuilder(routineName, context)
			routineInitializer.accept(routineBuilder.start())
			call(routineBuilder)
		}

		def call(Consumer<RoutineStartBuilder> routineInitializer) {
			anonymousRoutineCounter++
			call('''«reaction.name.toFirstLower»Repair«IF anonymousRoutineCounter !== 1»anonymousRoutineCounter«ENDIF»''',
				routineInitializer)
		}
	}

	static class PreconditionOrRoutineCallBuilder extends RoutineCallBuilder {
		private new(FluentReactionBuilder builder) {
			super(builder)
		}

		def with(Function<ReactionTypeProvider, XExpression> expressionProvider) {
			reaction.trigger.precondition = ReactionsLanguageFactory.eINSTANCE.createPreconditionCodeBlock => [
				code = XbaseFactory.eINSTANCE.createXBlockExpression.whenJvmTypes [
					expressions += extractExpressions(expressionProvider.apply(typeProvider))
				]
			]
			return new RoutineCallBuilder(builder)
		}

	}

	static class ReactionTypeProvider extends AbstractTypeProvider<FluentReactionBuilder> {
		val extension FluentReactionBuilder builderAsExtension

		protected new(IJvmTypeProvider delegate, FluentReactionBuilder builder, XExpression scopeExpression) {
			super(delegate, builder, scopeExpression)
			builderAsExtension = builder
		}
	}

	def private requiredArgumentsFrom(FluentRoutineBuilder routineBuilder, JvmOperation routineCallMethod) {
		val parameterList = new ArrayList<XExpression>(3)
		if (routineBuilder.requireAffectedEObject) {
			parameterList += routineCallMethod.argument(CHANGE_AFFECTED_ELEMENT_ATTRIBUTE)
		}
		if (routineBuilder.requireNewValue) {
			parameterList += routineCallMethod.argument(CHANGE_NEW_VALUE_ATTRIBUTE)
		}
		if (routineBuilder.requireOldValue) {
			parameterList += routineCallMethod.argument(CHANGE_OLD_VALUE_ATTRIBUTE)
		}
		return parameterList
	}

	def private argument(JvmOperation routineCallMethod, String parameterName) {
		val parameter = routineCallMethod.parameters.findFirst[name == parameterName]
		if (parameter === null) {
			throw new IllegalStateException('''The reaction “«reaction.name»” does not provide a value called “«parameterName»”!''')
		}
		XbaseFactory.eINSTANCE.createXFeatureCall => [
			feature = parameter
		]
	}

	def private getRoutineCallMethod() {
		val routineCallMethod = context.jvmModelAssociator.getPrimaryJvmElement(reaction.callRoutine.code)
		if (routineCallMethod instanceof JvmOperation) {
			return routineCallMethod
		}
		throw new IllegalStateException('''Could not find the routine call method corresponding to the routine call of the reaction “«reaction.name»”''')
	}

	def package getReaction() {
		reaction
	}

	def private getTypeProvider(XExpression scopeExpression) {
		val delegateTypeProvider = context.typeProviderFactory.findOrCreateTypeProvider(
			attachedReactionsFile.eResource.resourceSet)
		new ReactionTypeProvider(delegateTypeProvider, this, scopeExpression)
	}

	override toString() {
		'''reaction builder for “«reaction.name»”'''
	}

	override protected getCreatedElementName() {
		reaction.name
	}

	override protected getCreatedElementType() {
		"reaction"
	}

}
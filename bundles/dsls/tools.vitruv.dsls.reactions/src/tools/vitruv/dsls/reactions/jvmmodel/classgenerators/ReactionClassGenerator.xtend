package tools.vitruv.dsls.reactions.jvmmodel.classgenerators

import org.eclipse.xtext.common.types.JvmGenericType
import org.eclipse.xtext.common.types.JvmVisibility
import org.eclipse.xtext.common.types.JvmOperation
import static tools.vitruv.dsls.reactions.api.generator.ReactionsLanguageGeneratorConstants.*;
import tools.vitruv.dsls.reactions.reactionsLanguage.PreconditionCodeBlock
import tools.vitruv.dsls.reactions.helper.ClassNamesGenerators.ClassNameGenerator
import tools.vitruv.extensions.dslsruntime.reactions.AbstractReactionRealization
import tools.vitruv.framework.change.echange.EChange
import tools.vitruv.framework.change.echange.feature.FeatureEChange
import static tools.vitruv.dsls.reactions.helper.ReactionsLanguageConstants.*;
import tools.vitruv.dsls.reactions.reactionsLanguage.Reaction
import static extension tools.vitruv.dsls.reactions.helper.ClassNamesGenerators.*
import tools.vitruv.dsls.reactions.reactionsLanguage.ModelChange
import org.eclipse.xtend2.lib.StringConcatenationClient
import tools.vitruv.framework.change.echange.eobject.EObjectExistenceEChange
import tools.vitruv.framework.change.echange.feature.single.ReplaceSingleValuedFeatureEChange
import tools.vitruv.framework.change.echange.eobject.EObjectSubtractedEChange
import tools.vitruv.framework.change.echange.eobject.EObjectAddedEChange
import tools.vitruv.framework.change.echange.compound.CreateAndInsertEObject
import tools.vitruv.framework.change.echange.compound.RemoveAndDeleteEObject
import tools.vitruv.framework.change.echange.compound.CreateAndReplaceAndDeleteNonRoot
import tools.vitruv.dsls.reactions.helper.AccessibleElement
import static extension tools.vitruv.dsls.reactions.helper.ChangeTypeRepresentationExtractor.*
import tools.vitruv.dsls.reactions.helper.ChangeTypeRepresentationExtractor.ChangeTypeRepresentation
import tools.vitruv.dsls.reactions.helper.ChangeTypeRepresentationExtractor.AtomicChangeTypeRepresentation

class ReactionClassGenerator extends ClassGenerator {
	protected final Reaction reaction;
	protected final ChangeTypeRepresentation change;
	protected final boolean hasPreconditionBlock;
	private final ClassNameGenerator reactionClassNameGenerator;
	private final UserExecutionClassGenerator userExecutionClassGenerator;
	private final ClassNameGenerator routinesFacadeClassNameGenerator;
	
	private static final String affectedEObjectAttribute = "affectedEObject";
	private static final String affectedFeatureAttribute = "affectedFeature";
	private static final String oldValueAttribute = "oldValue";
	private static final String newValueAttribute = "newValue";
	
	new(Reaction reaction, TypesBuilderExtensionProvider typesBuilderExtensionProvider) {
		super(typesBuilderExtensionProvider);
		if (reaction?.trigger == null || reaction?.callRoutine == null) {
			throw new IllegalArgumentException();
		}
		this.reaction = reaction;
		this.hasPreconditionBlock = reaction.trigger.precondition != null;
		this.change = reaction.trigger.extractChangeTypeRepresentation();
		this.reactionClassNameGenerator = reaction.reactionClassNameGenerator;
		this.routinesFacadeClassNameGenerator = reaction.reactionsSegment.routinesFacadeClassNameGenerator;
		this.userExecutionClassGenerator = new UserExecutionClassGenerator(typesBuilderExtensionProvider, reaction, 
			reactionClassNameGenerator.qualifiedName + "." + EFFECT_USER_EXECUTION_SIMPLE_NAME);
	}
		
	public override JvmGenericType generateClass() {
		generateMethodGetExpectedChangeType();
		generateMethodCheckPrecondition();
		generateMethodExecuteReaction();
				
		reaction.toClass(reactionClassNameGenerator.qualifiedName) [
			visibility = JvmVisibility.DEFAULT;
			superTypes += typeRef(AbstractReactionRealization);
			addConstructor(it);
			members += generatedMethods;
			members += userExecutionClassGenerator.generateClass();
		];
	}
	
	protected def void addConstructor(JvmGenericType clazz) {
		clazz.members += clazz.toConstructor [
			visibility = JvmVisibility.PUBLIC;
			val userInteractingParameter = generateUserInteractingParameter();
			parameters += userInteractingParameter
			body = '''super(«userInteractingParameter.name»);'''
		]
	}
	
	protected def generateMethodGetExpectedChangeType() {
		val methodName = "getExpectedChangeType";
		return getOrGenerateMethod(methodName, typeRef(Class, wildcardExtends(typeRef(EChange)))) [
			static = true;
			body = '''return «change.changeType».class;'''
		];
	}
	
	/**
	 * Generates method: applyChange
	 * 
	 * <p>Applies the given change to the specified reaction. Executes the reaction if all preconditions are fulfilled.
	 * 
	 * <p>Method parameters are:
	 * <li>1. change: the change event ({@link EChange})
	 * <li>2. blackboard: the {@link Blackboard} containing the {@link CorrespondenceModel} 
	 * 
	 */
	protected def generateMethodExecuteReaction() {
		val methodName = "executeReaction";
		val changeParameterList = generatePropertiesParameterList(change.relevantChangeTypeRepresentation);
		val callRoutineMethod = userExecutionClassGenerator.generateMethodCallRoutine(reaction.callRoutine, 
			changeParameterList, typeRef(routinesFacadeClassNameGenerator.qualifiedName));
		return getOrGenerateMethod(methodName, typeRef(Void.TYPE)) [
			visibility = JvmVisibility.PUBLIC;
			val changeParameter = generateUntypedChangeParameter();
			parameters += changeParameter;
			val typedChangeName = "typedChange";
			val relevantChange = change.relevantChangeTypeRepresentation;
			body = '''
				«generateRelevantChangeAssignmentCode(changeParameter.name, true, typedChangeName)»
				«generatePropertiesAssignmentCode(relevantChange, typedChangeName)»
				«routinesFacadeClassNameGenerator.qualifiedName» routinesFacade = new «routinesFacadeClassNameGenerator.qualifiedName»(this.executionState, this);
				«userExecutionClassGenerator.qualifiedClassName» userExecution = new «userExecutionClassGenerator.qualifiedClassName»(this.executionState, this);
				userExecution.«callRoutineMethod.simpleName»(«
					FOR parameter : changeParameterList SEPARATOR ", " AFTER ", "»«parameter.name»«ENDFOR»routinesFacade);
			'''
		];
	}
	
	private def StringConcatenationClient generateRelevantChangeAssignmentCode(String originalChangeVariableName, boolean originalVariableIsUntyped, String relevantChangeVariableName) {
		val relevantChange = change.relevantChangeTypeRepresentation;
			val typedChangeString = change.typedChangeTypeRepresentation;
			val typedRelevantChangeString = relevantChange.typedChangeTypeRepresentation;
			val isCompoundChange = relevantChange != change;
			return '''
				«typedRelevantChangeString» «relevantChangeVariableName» = «
					»«IF isCompoundChange»(«IF originalVariableIsUntyped»(«typedChangeString»)«ENDIF»«originalChangeVariableName»).«
					»«IF CreateAndInsertEObject.isAssignableFrom(change.changeType)»getInsertChange()«
					ELSEIF RemoveAndDeleteEObject.isAssignableFrom(change.changeType)»getRemoveChange()«
					ELSEIF CreateAndReplaceAndDeleteNonRoot.isAssignableFrom(change.changeType)»getReplaceChange()«ENDIF»;
				«ELSE»
					«IF originalVariableIsUntyped»(«typedChangeString»)«ENDIF»«originalChangeVariableName»;
				«ENDIF»
				'''
	}
	
	private def Iterable<AccessibleElement> generatePropertiesParameterList(AtomicChangeTypeRepresentation changeType) {
		val result = <AccessibleElement>newArrayList();
		if (changeType.affectedElementClass != null) {
			result.add(new AccessibleElement(affectedEObjectAttribute, typeRef(changeType.affectedElementClass)));
		}
		if (changeType.affectedFeature != null) {
			result.add(new AccessibleElement(affectedFeatureAttribute, typeRef(changeType.affectedFeature.eClass.instanceClass)));
		}
		if (changeType.hasOldValue) {
			result.add(new AccessibleElement(oldValueAttribute, typeRef(changeType.affectedValueClass)));
		}
		if (changeType.hasNewValue) {
			result.add(new AccessibleElement(newValueAttribute, typeRef(changeType.affectedValueClass)));
		}
		return result;
	}
	
	private def StringConcatenationClient generatePropertiesAssignmentCode(AtomicChangeTypeRepresentation change, String typedChangeVariableName) {
		'''
		«IF change.affectedElementClass != null»
			«change.affectedElementClass» «affectedEObjectAttribute» = «typedChangeVariableName».get«affectedEObjectAttribute.toFirstUpper»();
		«ENDIF»
		«IF change.affectedFeature != null»
			«change.affectedFeature.eClass.instanceClass» «affectedFeatureAttribute» = «typedChangeVariableName».get«affectedFeatureAttribute.toFirstUpper»();
		«ENDIF»
		«IF change.hasOldValue»
			«change.affectedValueClass» «oldValueAttribute» = «typedChangeVariableName».get«oldValueAttribute.toFirstUpper»();
		«ENDIF»
		«IF change.hasNewValue»
			«change.affectedValueClass» «newValueAttribute» = «typedChangeVariableName».get«newValueAttribute.toFirstUpper»();
		«ENDIF»
		'''
	}
			
	protected def generateMethodCheckPrecondition() {
		val methodName = PRECONDITION_METHOD_NAME;
		val changePropertiesCheckMethod = generateMethodCheckChangeProperties();
		val userDefinedPreconditionMethod = if (hasPreconditionBlock) {
			generateMethodCheckUserDefinedPrecondition(reaction.trigger.precondition);	
		}
		return getOrGenerateMethod(methodName, typeRef(Boolean.TYPE)) [
			val changeParameter = generateUntypedChangeParameter(reaction);
			visibility = JvmVisibility.PUBLIC;
			parameters += changeParameter
			val typedChangeVariableName = "typedChange";
			val relevantChange = change.relevantChangeTypeRepresentation;
			body = '''
				if (!(«changeParameter.name» instanceof «change.changeType»)) {
					return false;
				}
				if (!«changePropertiesCheckMethod.simpleName»(«changeParameter.name»)) {
					return false;
				}
				«IF hasPreconditionBlock»
					«generateRelevantChangeAssignmentCode(changeParameter.name, true, typedChangeVariableName)»
					«generatePropertiesAssignmentCode(relevantChange, typedChangeVariableName)»
					if (!«userDefinedPreconditionMethod.simpleName»(«
						FOR parameter : generatePropertiesParameterList(relevantChange) SEPARATOR ", "»«parameter.name»«ENDFOR»)) {
						return false;
					}
				«ENDIF»
				getLogger().debug("Passed precondition check of reaction " + this.getClass().getName());
				return true;
				'''
		];
	}

	protected def JvmOperation generateMethodCheckUserDefinedPrecondition(PreconditionCodeBlock preconditionBlock) {
		val methodName = USER_DEFINED_TRIGGER_PRECONDITION_METHOD_NAME;
		return preconditionBlock.getOrGenerateMethod(methodName, typeRef(Boolean.TYPE)) [
			visibility = JvmVisibility.PRIVATE;
			parameters += generateAccessibleElementsParameters(generatePropertiesParameterList(change.relevantChangeTypeRepresentation));
			body = preconditionBlock.code;
		];		
	}
	
	/**
	 * Generates method: checkChangedObject : boolean
	 * 
	 * <p>Checks if the currently changed object equals the one specified in the reaction.
	 * 
	 * <p>Methods parameters are:
	 * 	<li>1. change: the change event ({@link EChange})</li>
	 */
	protected def generateMethodCheckChangeProperties() {
		val methodName = "checkChangeProperties";
		
		if (!(reaction.trigger instanceof ModelChange)) {
			throw new IllegalStateException();
		}
		
		return getOrGenerateMethod(methodName, typeRef(Boolean.TYPE)) [
			visibility = JvmVisibility.PRIVATE;
			val changeParameter = generateUntypedChangeParameter();
			parameters += changeParameter;
			val relevantChangeParamterName = "relevantChange";
			body = '''
				«generateRelevantChangeAssignmentCode(changeParameter.name, true, relevantChangeParamterName)»
				«generateElementChecks(change.relevantChangeTypeRepresentation, relevantChangeParamterName)»
				return true;
			'''
		];
	}
	
	private def StringConcatenationClient generateElementChecks(AtomicChangeTypeRepresentation change, String changeParameterName) '''
		«generateExistenceCheck(change, changeParameterName)»
		«generateUsageCheck(change, changeParameterName)»
	'''
	
	private def StringConcatenationClient generateUsageCheck(AtomicChangeTypeRepresentation change, String changeParameterName) '''
		«IF FeatureEChange.isAssignableFrom(change.changeType)»
			// Check affected object
			if (!(«changeParameterName».getAffectedEObject() instanceof «change.affectedElementClass»)) {
				return false;
			}
			// Check feature
			if (!«changeParameterName».getAffectedFeature().getName().equals("«change.affectedFeature.name»")) {
				return false;
			}
		«ENDIF»
		«generateAdditiveSubtractiveCheck(change, changeParameterName)»
	'''
	
	private def StringConcatenationClient generateAdditiveSubtractiveCheck(AtomicChangeTypeRepresentation change, String changeParameterName) '''
		«IF EObjectSubtractedEChange.isAssignableFrom(change.changeType)»
			if («IF ReplaceSingleValuedFeatureEChange.isAssignableFrom(change.changeType)»«changeParameterName».isFromNonDefaultValue() && «
				ENDIF»!(«changeParameterName».getOldValue() instanceof «change.affectedValueClass»)
			) {
				return false;
			}
		«ENDIF»
		«IF EObjectAddedEChange.isAssignableFrom(change.changeType)»
			if («IF ReplaceSingleValuedFeatureEChange.isAssignableFrom(change.changeType)»«changeParameterName».isToNonDefaultValue() && «
				ENDIF»!(«changeParameterName».getNewValue() instanceof «change.affectedValueClass»)) {
				return false;
			}
		«ENDIF»
	'''
	
	private def StringConcatenationClient generateExistenceCheck(AtomicChangeTypeRepresentation change, String changeParameterName) '''
		«IF EObjectExistenceEChange.isAssignableFrom(change.changeType)»
			if (!(«changeParameterName».getAffectedEObject() instanceof «change.affectedElementClass»)) {
				return false;
			}
		«ENDIF»
	'''
	
}
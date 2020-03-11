package tools.vitruv.dsls.commonalities.generator

import tools.vitruv.dsls.commonalities.language.Commonality
import tools.vitruv.dsls.commonalities.language.Participation
import tools.vitruv.dsls.commonalities.language.ParticipationClass
import tools.vitruv.dsls.reactions.builder.FluentReactionBuilder

import static com.google.common.base.Preconditions.*

import static extension tools.vitruv.dsls.commonalities.generator.ReactionsGeneratorConventions.*
import static extension tools.vitruv.dsls.commonalities.generator.ReactionsHelper.*
import static extension tools.vitruv.dsls.commonalities.language.extensions.CommonalitiesLanguageModelExtensions.*

class ParticipationExistenceChangeReactionsBuilder extends ReactionsSubGenerator<ParticipationExistenceChangeReactionsBuilder> {

	Participation participation
	Commonality commonality

	def package forParticipation(Participation participation) {
		this.participation = participation
		this.commonality = participation.containingCommonality
		return this
	}

	def package Iterable<FluentReactionBuilder> getReactions() {
		checkState(participation !== null, "No participation to create reactions for was set!")
		checkState(generationContext !== null, "No generation context was set!")

		return participation.classes
			.filter[!isForResource]
			.flatMap[#[
				reactionForParticipationClassCreate,
				reactionForParticipationClassDelete,
				reactionForParticipationRootInsert
			]]
	}

	def private reactionForParticipationClassCreate(ParticipationClass participationClass) {
		create.reaction('''«participationClass.participation.name»_«participationClass.name»Create''')
			.afterElement(participationClass.changeClass).created
			.call [
				match [
					requireAbsenceOf(commonality.changeClass).correspondingTo.affectedEObject
						.taggedWith(participationClass.correspondenceTag)
				]
				.action [
					vall(INTERMEDIATE).create(commonality.changeClass).andInitialize [
						assignStagingId(variable(INTERMEDIATE))
					]
					addCorrespondenceBetween(INTERMEDIATE).and.affectedEObject
						.taggedWith(participationClass.correspondenceTag)
				]
			]
	}

	def private reactionForParticipationClassDelete(ParticipationClass participationClass) {
		create.reaction('''«participationClass.participation.name»_«participationClass.name»Delete''')
			.afterElement(participationClass.changeClass).deleted
			.call [
				match [
					vall(INTERMEDIATE).retrieveAsserted(commonality.changeClass).correspondingTo.affectedEObject
				]
				action [
					delete(INTERMEDIATE)
				]
			]
	}

	def private reactionForParticipationRootInsert(ParticipationClass participationClass) {
		create.reaction('''«participationClass.participation.name»_«participationClass.name»RootInsert''')
			// note: may be a commonality participation
			.afterElementInsertedAsRoot(participationClass.changeClass)
			.call(#[
				participationClass.intermediateResourceBridgeRoutine,
				getInsertRoutine(participationClass.participation, commonality)
			].filterNull)
	}
}

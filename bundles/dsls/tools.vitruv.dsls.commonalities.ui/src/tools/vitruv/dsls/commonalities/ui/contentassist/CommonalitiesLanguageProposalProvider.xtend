package tools.vitruv.dsls.commonalities.ui.contentassist

import com.google.inject.Inject
import com.google.inject.Provider
import org.eclipse.xtext.ui.editor.contentassist.ContentAssistContext

/**
 * See https://www.eclipse.org/Xtext/documentation/304_ide_concepts.html#content-assist
 * on how to customize the content assistant.
 */
class CommonalitiesLanguageProposalProvider extends AbstractCommonalitiesLanguageProposalProvider {
	
	@Inject Provider<QualifiedMetaclassProposalFactory> qMetaclassProposalFactory
	@Inject Provider<QualifiedParticipationAttributeProposalFactory> qPartAttributeProposalFactory
	@Inject Provider<UnqualifiedMetaclassProposalFactory> uMetaclassProposalFactory
	@Inject Provider<DomainPrefixProposalFactory> domainPrefixProposalFactory
	
	override getProposalFactory(String ruleName, ContentAssistContext contentAssistContext) {
		switch(ruleName) {
			case "QualifiedMetaclass":
				qMetaclassProposalFactory.init(contentAssistContext)
				
			case "UnqualifiedMetaclass":
				uMetaclassProposalFactory.init(contentAssistContext)
			
			case "QualifiedParticipationAttribute":
				qPartAttributeProposalFactory.init(contentAssistContext)
				
			case "DomainReference":
				domainPrefixProposalFactory.init(contentAssistContext)
			
			default:
				super.getProposalFactory(ruleName, contentAssistContext)
		}
	}
	
	/*
	override completeParticipationClassDeclaration_SuperMetaclass(EObject model, Assignment assignment, ContentAssistContext context, ICompletionProposalAcceptor acceptor) {
		super.completeParticipationClassDeclaration_SuperMetaclass(model, assignment, context, acceptor)
	}
	
	override completeParticipationDeclaration_Domain(EObject model, Assignment assignment, ContentAssistContext context, extension ICompletionProposalAcceptor acceptor) {
		// propose not only domains but also domain attributes
		val scopeDomains = scopeProvider.getScope(model, PARTICIPATION__DOMAIN).allElements
		
		scopeDomains
			.map(domainPrefixProposalFactory.init(context).fun)
			.forEach [accept]
		
		scopeDomains
			.map [EObjectOrProxy]
			.filter(Domain)
			.flatMap [metaclasses]
			.map(descriptionProvider)
			.map(qMetaclassProposalFactory.init(context).fun)
			.forEach [accept]
	}*/
	
	def private <T extends CommonalitiesLanguageProposalFactory> init(Provider<T> factory, ContentAssistContext contentAssistContext) {
		factory.get() => [
			context = contentAssistContext
			proposalProvider = this
		]
	}
}

import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
import { useAuth } from '../context/AuthContext';
import { chatWithAI } from '../services/api';

function normalizeAssistantMarkdown(text) {
    if (typeof text !== 'string') return String(text ?? '');

    let t = text.trim();

    // 如果模型把 markdown 包在 ```markdown ... ``` 里，去掉外层代码围栏
    const fenceMatch = t.match(/^```(?:markdown|md)?\s*([\s\S]*?)\s*```$/i);
    if (fenceMatch) {
        t = fenceMatch[1].trim();
    }

    // 处理常见转义：\#\#、\*\*、\n
    t = t
        .replace(/\\([#*_`[\]()])/g, '$1')
        .replace(/\\n/g, '\n');

    return t;
}

function ChatWithAI() {
    const navigate = useNavigate();
    const { token, user } = useAuth();

    const [messages, setMessages] = useState([
        {
            role: 'assistant',
            content:
                'Hi! You can use commands:\n/match -> match your resume with career fair companies\n/optimize -> optimize and polish your resume text\n/pitch -> generate a tailored elevator pitch\n\nYou can also add context, e.g. /pitch backend internship.',
        },
    ]);
    const [input, setInput] = useState('');
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');

    const sendMessage = async () => {
        const question = input.trim();
        if (!question || loading) return;

        const nextMessages = [...messages, { role: 'user', content: question }];
        setMessages(nextMessages);
        setInput('');
        setLoading(true);
        setError('');

        try {
            const result = await chatWithAI(token, question, nextMessages);

            if (result.error) {
                throw new Error(result.details || result.error);
            }

            const rawAnswer = result.answer || 'I could not generate a response.';
            const normalizedAnswer = normalizeAssistantMarkdown(rawAnswer);

            setMessages([
                ...nextMessages,
                {
                    role: 'assistant',
                    content: normalizedAnswer,
                },
            ]);
        } catch (err) {
            setError(err.message || 'Failed to talk to AI.');
        } finally {
            setLoading(false);
        }
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        await sendMessage();
    };

    const handleKeyDown = async (e) => {
        if (e.key === 'Enter' && !e.shiftKey) {
            e.preventDefault();
            await sendMessage();
        }
    };

    return (
        <div className="chat-page">
            <nav className="navbar">
                <div className="nav-brand">
                    <h2>AI4Careers</h2>
                </div>
                <div className="nav-links">
                    <span className="user-name">{user ? `Hello, ${user.name}` : 'AI Chat'}</span>
                    <button className="btn-secondary" onClick={() => navigate('/dashboard')}>
                        Back to Dashboard
                    </button>
                </div>
            </nav>

            <div className="chat-shell">
                <div className="chat-header-card">
                    <h1>Chat With AI</h1>
                    <p>
                        Ask about company fit, resume alignment, sponsorship constraints, locations,
                        or how to prioritize the career fair.
                    </p>
                </div>

                <div className="chat-window">
                    {messages.map((msg, idx) => (
                        <div
                            key={idx}
                            className={`chat-bubble ${msg.role === 'user' ? 'chat-bubble-user' : 'chat-bubble-assistant'}`}
                        >
                            <div className="chat-role">{msg.role === 'user' ? 'You' : 'AI'}</div>
                            <div className="chat-content">
                                {msg.role === 'assistant' ? (
                                    <div className="chat-markdown">
                                        <ReactMarkdown remarkPlugins={[remarkGfm]}>
                                            {normalizeAssistantMarkdown(msg.content)}
                                        </ReactMarkdown>
                                    </div>
                                ) : (
                                    <div className="chat-plain">{msg.content}</div>
                                )}
                            </div>
                        </div>
                    ))}

                    {loading && (
                        <div className="chat-bubble chat-bubble-assistant">
                            <div className="chat-role">AI</div>
                            <div className="chat-content">Thinking...</div>
                        </div>
                    )}
                </div>

                {error && <div className="error-message">{error}</div>}

                <form className="chat-input-bar" onSubmit={handleSubmit}>
                    <textarea
                        value={input}
                        onChange={(e) => setInput(e.target.value)}
                        onKeyDown={handleKeyDown}
                        placeholder="Try /match, /optimize, /pitch, or ask a normal question..."
                        rows={3}
                    />
                    <button type="submit" className="btn-primary" disabled={loading}>
                        {loading ? 'Sending...' : 'Send'}
                    </button>
                </form>
            </div>
        </div>
    );
}

export default ChatWithAI;
